#!/usr/bin/perl -w

########################
#
# svn2exist.pl
# Author: Peter Stadler <stadler at weber hyphen gesamtausgabe dot de>
# Version: 3.6
# Last change on Dec 17, 2012
#
########################

use strict;
use utf8;
use Encode;
use RPC::XML;
use RPC::XML::Client;
use Getopt::Long; #qw(:config posix_default);
use 5.6.0;
use XML::LibXML;
use LWP::UserAgent;
use SVN::Client;
use SVN::Core;
use Term::ReadKey;
use Digest::MD5 qw(md5_hex);
use FileHandle;
use DateTime;
binmode(STDOUT, ":utf8");

########################
# local settings
# change here
########################
our $errorLogFile = "/Groups/Subversion/WeGA/hooks/svn2exist_error.log"; # Complete filename with path for error log file
our $URL = "http://admin:\@localhost:8085/exist/xmlrpc"; # url of eXist db server.
our $proxyURL = "";
our $svnChangeHistoryFilePath = "/db/webapp/xml/svnChangeHistory.xml";
$RPC::XML::ENCODING = 'utf-8';
our $excludePattern = "Skripte|Material(ien)?|temp|odd|^\/\$|testing|images";
our %pathReplacements = (
    "/webapp/indices" => "/system/config/db",
    "/trunk" => "/db",
    "/branches/release" => "/db"
);
our @foldersToIndex = ("/db/letters", "/db/persons", "/db/works", "/db/diaries", "/db/webapp", "/db/iconography", "/db/news", "/db/var", "/db/writings");
########################
# end of local settings
########################

GetOptions("update" => \our $update,
			"build" => \our $build,
			"rev=i" => \our $rev,
			"repoPath|p=s" => \our $repoPath,
			"help|?" => \our $help,
			"verbose" => \our $verbose,
			"test" => \our $test,
			"createSVNChangeHistoryOnly" => \our $createSVNChangeHistoryOnly,
			"overwrite|w" => \our $overwrite);

########################
# global variables
########################
our $parser = XML::LibXML->new() or die "new parser failed";
our $svnChangeHistory;
our $svnChangeHistoryDocRoot;
our $rpcClient;
our $svnHeadRevision;
our $svnRepoRootURL;
our @globalChangedPaths = ();
unless (defined($overwrite)){$verbose = 1}; # switch on verbose output if --overwrite is not set


########################
# main routine
########################
if (defined($help))     {printHelp();}
elsif (defined($test))  {
    print "Dies ist ein Test\n";
    #createRPCClient();
    #createSVNClient();
    #sleep();
    #eXistReindexCollection('/db/persons');
    #$svnClient->cat (\*STDOUT, 
    #'file:///Groups/Subversion/WeGA/trunk/odd/WeGA_letters.odd.xml'
    #'https://menotti/svn/WeGA/trunk/odd/WeGA_letters.odd.xml'
    #,'HEAD');
    #$svnClient->info('/Users/peter/Documents/WeGA/Subversion/trunk/odd/WeGA_var.odd.xml', undef, 'HEAD', \&svnReceiver, 0);
    #my %foohash = %{$svnClient->ls($repoPath, $rev, 0)};
    #callcreateNormDates('letters');
    #my $md5_data = "test";
    #my $md5_hash = md5_hex( $md5_data );
    #print "$md5_hash\n";
    #updateSvnChangeHistory(2000, 1);
    #eXistDbCreateCollection('webapp/tmp');
    #eXistSetPermissions('webapp/tmp', 'guest', 'guest', 493);
    #createInitialSvnChangeHistory($rev);
	#updateSvnChangeHistory($rev, 0);
	#print $svnChangeHistory->toString("2");
	#eXistDbParse($svnChangeHistory->toString("2"), $svnChangeHistoryFilePath);
	#callcreateNormDates('persons', 'diaries', 'works', 'news', 'writings', 'letters');
	#foreach my $path ( keys(%foohash) ) {
	#   unless ($path =~ m/$excludePattern/){
	#       #print $path, "\n";
	#       eXistReindexCollection("/".$dbTargetRoot."/".$path);
	#   }
    #}
    print "update done\n";
}

elsif (defined($build) and defined($repoPath) and !defined($update) and !defined($test) and !defined($createSVNChangeHistoryOnly)) {
    if(defined($overwrite)) {createDB();}
    else {
        printOverwriteWarning();
        createDB();
        printOverwriteWarning();
    }
}

elsif (defined($update) and defined($repoPath) and !defined($build) and !defined($test) and !defined($createSVNChangeHistoryOnly)) {
    if(defined($overwrite)) {updateDB();}
    else {
        printOverwriteWarning();
        updateDB();
        printOverwriteWarning();
    }
}

elsif (defined($createSVNChangeHistoryOnly) and defined($repoPath) and !defined($build) and !defined($test) and !defined($update)) {
    createSVNChangeHistoryOnly();
} 

else {printHelp()};

########################
# Update of eXist db
########################
sub updateDB {
    createRPCClient();
    setSvnHeadNRepoURL();
    my $svnClient = createSVNClient();
    my $svn_log_changed_path_t_Object;
    my $targetPath;
	my $rpcOptions = RPC::XML::struct->new('indent' => 'yes','encoding' => 'UTF-8');      
	$svnChangeHistory = $parser->parse_string(eXistGetDocumentAsString($svnChangeHistoryFilePath,$rpcOptions));
	$svnChangeHistoryDocRoot = $svnChangeHistory->documentElement();
	my $latestExistRevision = $svnChangeHistoryDocRoot->getAttribute("head");
	
	if (defined($verbose)){
        print "eXist-db: current stored revision is $latestExistRevision\n";
    }
	
	if ($latestExistRevision >= $rev){
		print "No need to update because eXist revision is greater or equal to $rev!\n";
		printErrorLog("Update failed: revision argument was $rev and eXist db had revision $latestExistRevision");
		exit();
	}
	if ($rev > $svnHeadRevision){
		print "Cannot update because youngest revision is less or equal to $rev!\n";
		printErrorLog("Update failed: revision argument was $rev and youngest revision $svnHeadRevision");
		exit();
	}
	
	my $log_receiver = sub {
	   my ($changed_paths, $revision, $author, $date, $message, $pool) = @_;
	   #print $changed_paths, "\n";
	   my %changedPaths = %{$changed_paths};
	   @globalChangedPaths = keys(%changedPaths);
	   if (defined($verbose)){print "*** Uploading revision $revision ***\n"};
	   
	   ##############################
	   # Zuerst loop über alle Ordner
	   ##############################
	   foreach my $i (keys(%changedPaths)) {
	       $svn_log_changed_path_t_Object = $changedPaths{$i};
	       #print $i, " : ";
	       #print $svn_log_changed_path_t_Object->action(), "\n";
	       unless ($i =~ m/\./ or $i =~ m/$excludePattern/) { # ACHTUNG: Ordnernamen dürfen keine Punkte enthalten!
	           $targetPath = $i;
	           foreach my $k (keys %pathReplacements) {
	               $targetPath =~ s/$k/$pathReplacements{$k}/;
	           }
	           if($svn_log_changed_path_t_Object->action() eq "A") {
	               #eXistDbCreateCollection($targetPath);
	               $svnClient->info($svnRepoRootURL.$i, $revision, $revision, \&addFileOrFolder, 1 );
	           }
	           elsif($svn_log_changed_path_t_Object->action() eq "D") {
	               eXistDbRemoveCollection($targetPath);
	           }
	           #else {
	           #    print $i, " : ";
	           #    print $svn_log_changed_path_t_Object->action(), "\n";
               #}
           }
        }
        ##############################
        # danach die Dateien
        ##############################
        foreach my $i (keys(%changedPaths)) { 
            $svn_log_changed_path_t_Object = $changedPaths{$i};
            if ($i =~ m/\./ and not $i =~ m/$excludePattern/) {
                $targetPath = $i;
                foreach my $k (keys %pathReplacements) {
	               $targetPath =~ s/$k/$pathReplacements{$k}/;
                }
                if($svn_log_changed_path_t_Object->action() =~ m/A|M|R/) {
                    my $subSvnClient = createSVNClient();
                    saveToDb($svnRepoRootURL.$i, $targetPath, $revision, \$subSvnClient);
                    modifyChangeEntry($svnRepoRootURL.$i, $targetPath, $revision, \$subSvnClient);
                }
                elsif($svn_log_changed_path_t_Object->action() eq "D") {
                    eXistDbRemove($targetPath);
                    removeChangeEntry($targetPath);
                }
                #else {
                #    print $i, " : ";
                #    print $svn_log_changed_path_t_Object->action(), "\n";
                #}
            }
        }
        return 0;
    };

	$svnClient->log($repoPath, $latestExistRevision+1, $rev, 1, 0, $log_receiver);
	
	$svnChangeHistoryDocRoot->setAttribute("head", $rev);
	eXistDbParse($svnChangeHistory->toString("2"), $svnChangeHistoryFilePath);
	
    return 0;
    
    ## TODO
    # Ergebnis von svn->log eindampfen auf distinct-values, d.h. wenn in rev 4-100 immer nur Datei A verändert wird, dann muss die nur einmal hochgeladen werden ...
    # Wenn Index-Dateien verändert wurden sollte ein Reindex angestossen werden
}

########################
# Build new eXist db from scratch
########################
sub createDB {
    createRPCClient();
    setSvnHeadNRepoURL();
    createSvnChangeHistory();
    
    my $svnClient = createSVNClient();
	$svnClient->info( $repoPath, $rev, $rev, \&addFileOrFolder, 1 );
	#print $svnChangeHistory->toString("2");
    
	eXistDbCreateCollection('/db/webapp/tmp');
    eXistSetPermissions('/db/webapp/tmp', 'guest', 'guest', 493);
    eXistDbParse($svnChangeHistory->toString("2"), $svnChangeHistoryFilePath);
    
    # Reindexing all first level folders (simply reindexing root would take too long for the rpc timeout)
	foreach my $folder (@foldersToIndex) {
	   eXistReindexCollection($folder);
    }
    return 0;
}

########################
# Create only svnChangeHistoryFile
########################
sub createSVNChangeHistoryOnly {
    createRPCClient();
    setSvnHeadNRepoURL();
    createSvnChangeHistory();
    my $svnClient = createSVNClient();
    
    my $info_receiver = sub {
        my ($sourcePath, $info, $pool) = @_;
        my $svnFullPath = $info->URL;
        my $svnRepoPath = substr($svnFullPath, length($repoPath));
        
        if($svnFullPath =~ m/$excludePattern/ or isInList($svnRepoPath, @globalChangedPaths)) {
            if (defined($verbose)){print "-- skipping: ", $svnRepoPath, "\n"}
        }
        elsif($svnFullPath eq $repoPath){} # Ausschliessen des root-folders, z.B. http://host/svn/WeGA/trunk 
        else {
           my $targetPath = substr($svnFullPath, length($svnRepoRootURL));
           foreach my $i (keys %pathReplacements) {
               $targetPath =~ s/$i/$pathReplacements{$i}/;
           }
           if ($info->kind() == 1) {
               createChangeEntry($info, $targetPath);
           }
        }
    };
    $svnClient->info( $repoPath, $rev, $rev, $info_receiver, 1 );
    
    eXistDbParse($svnChangeHistory->toString("2"), $svnChangeHistoryFilePath);
    if (defined($verbose)){print $svnChangeHistory->toString("2"), "\n"}
    
    return 0;
}

sub printOverwriteWarning {
	print "WARNING: working in read-only mode. Changes will only be displayed but not uploaded to the eXist db.\n";
	print "To write changes to the db use option --overwrite\n";
}

sub printHelp {
	print "svn2exist 3.6 of 17 December 2012 by Peter Stadler.\n";
	print "The script tries to build or update an eXist database at localhost:8080\nfrom a subversion repository. One of --update or --build are mandatory\nas well as the path to the repository (--repoPath). If revision is\nomitted the head revision will be checked out.\n";
	print "This software is provided 'as is' and no responsibility can be taken from the author.\n\n";
	print "Usage: svn2exist (-bu | -u) -p=PathToRepository [-r=RevisionNumber]\n";
	print "  -b, --build\tbuild a new exist db from subversion\n";
	print "  -u, --update\tupdate existing db from subversion\n";
	print "  -h, --help\tprint this help\n";
	print "Options\n";
	print "  -p, --repoPath\tpath to subversion repository\n";
#	print "  -br, --branch\tbranch (e.g. trunk) of subversion repository to work with\n";
	print "  -r, --rev\trevision to update/checkout from subversion repository\n";
#	print "  -s, --skipRevisionCheck\tskip database query for last update\n\t\t(only reasonable when executed as subversion hook)\n";
	print "  -v, --verbose\tverbose output to stdout\n";
	print "  -w, --overwrite\toverwrites existing files (without this option\n\t\tpossible changes to the eXist db will only be displayed\n\t\tso --verbose is automatically set)\n";
}

#sub clearDBCache {
#    if (defined($verbose)){print "Clearing eXist cache\n"};
#    my $query = <<END;
#cache:clear()
#END
#    my $req = RPC::XML::request->new("executeQuery", RPC::XML::base64->new($query), "UTF-8");
#	if (defined($overwrite)){
#		my $resp = $rpcClient->send_request($req);
#		if($resp->is_fault) {
#			printErrorLog("Couldn't clear cache: ",$resp->string);
#		}
#		else {if (defined($verbose)){print "Success\n"};}
#	}
#}

sub addFileOrFolder {
    my ($sourcePath, $info, $pool) = @_;
    my $svnFullPath = $info->URL;
    my $svnRepoPath = substr($svnFullPath, length($repoPath));
    
    if($svnFullPath =~ m/$excludePattern/ or isInList($svnRepoPath, @globalChangedPaths)) {
        if (defined($verbose)){print "-- skipping: ", $svnRepoPath, "\n"}
    }
    elsif($svnFullPath eq $repoPath){} # Ausschliessen des root-folders, z.B. http://host/svn/WeGA/trunk 
    else {
       my $targetPath = substr($svnFullPath, length($svnRepoRootURL));
       foreach my $i (keys %pathReplacements) {
           $targetPath =~ s/$i/$pathReplacements{$i}/;
       }
       if ($info->kind() == 2) { # folder
           eXistDbCreateCollection($targetPath);
       } 
       elsif ($info->kind() == 1) { #file
           my $subSvnClient = createSVNClient();
           saveToDb($svnFullPath, $targetPath, $rev, \$subSvnClient);
           createChangeEntry($info, $targetPath);
       }
    }
    return 0;
};

# Checks if a provided element exists in the provided list
# Usage: isInList <needle element> <haystack list>
# Returns: 0/1
sub isInList {
    my $needle = shift;
    my @haystack = @_;
    foreach my $hay (@haystack) {
        if ( $needle eq $hay ) {
            return 1;
        }
    }
    return 0;
}

sub createRPCClient {
    unless(defined($rpcClient)) {
        if (defined($verbose)){print "Creating RPC Client\n"};
        $rpcClient = new RPC::XML::Client $URL;
        my $ua = $rpcClient->useragent;
        if($proxyURL =~ /\w/) {
            $ua->proxy(['http', 'https'], $proxyURL);
            $ua->env_proxy;
        }
        $ua->timeout(600); # timeout in seconds: "The requests is aborted if no activity on the connection to the server is observed for timeout seconds. This means that the time it takes for the complete transaction and the request() method to actually return might be longer." [http://search.cpan.org/~gaas/libwww-perl-6.02/lib/LWP/UserAgent.pm]
    }
}

# create $svnClient
sub createSVNClient {
    if (defined($verbose)){print "Creating SVN Client\n"};
    my $svnClient = new SVN::Client(auth => [
    SVN::Client::get_simple_provider()
    ,SVN::Client::get_simple_prompt_provider(\&svnSimplePrompt,2)
    ,SVN::Client::get_ssl_server_trust_prompt_provider(\&svnTrustCallback)
    ]);
    return $svnClient;
}

# set $headRevision, $rev (if not defined via command line parameter) and $svnRepoRootURL
sub setSvnHeadNRepoURL {
    my $svnClient = createSVNClient();
    my $receiver = sub {
        my( $path, $info, $pool ) = @_;
        $svnHeadRevision = $info->rev();
        $svnRepoRootURL = $info->repos_root_URL();
        return 0;
    };
    $svnClient->info( $repoPath, undef, 'HEAD', $receiver, 0 ); #$headRevision;
    unless (defined($rev)) {$rev = $svnHeadRevision;}
    if (defined($verbose)){
        print "Subversion Head Revision is $svnHeadRevision\n";
        print "Subversion Repository Root URL is $svnRepoRootURL\n";
    }
    return 0;
}

sub createSvnChangeHistory {
    unless(defined($svnChangeHistoryDocRoot)) {
        if (defined($verbose)){print "Creating SvnChangeHistory Document Root\n"};
        $svnChangeHistoryDocRoot = XML::LibXML::Element->new( "dictionary" );
    	$svnChangeHistoryDocRoot->setAttribute("xml:id", "svnChangeHistory");
    	$svnChangeHistoryDocRoot->setAttribute("head", $rev);
    }
    unless(defined($svnChangeHistory)) {
        if (defined($verbose)){print "Creating SvnChangeHistory File\n"};
        $svnChangeHistory = XML::LibXML->createDocument( "1.0", "UTF-8" );
    	$svnChangeHistory->setDocumentElement($svnChangeHistoryDocRoot);
    }
}

sub svnTrustCallback {
    my ($cred,$realm,$ifailed,$server_cert_info,$may_save) = @_;
    $cred->accepted_failures($SVN::Auth::SSL::CNMISMATCH);
}


sub svnSimplePrompt {
    my $cred = shift;
    my $realm = shift;
    my $default_username = shift;
    my $may_save = shift;
    my $pool = shift;
    
    print "Enter authentication info for realm: $realm\n";
    print "Username: ";
    my $username = <>;
    chomp($username);
    $cred->username($username);
    print "Password: ";
    ReadMode('noecho');
    my $password = ReadLine(0);
    chomp($password);
    $cred->password($password);
    $cred->may_save('1');
    ReadMode('normal');
    print "\n";
}

# void createChangeEntry (svn_info_t $info, string $targetPath)
sub createChangeEntry {
    my $info = $_[0];
    my $targetPath = $_[1];
    my $fullPath = $info->URL();
    my $author = $info->last_changed_author();
    my $dateTime = DateTime->from_epoch( epoch => substr($info->last_changed_date(), 0, 10) ); # die ersten 10 Stellen sind der Unix timestamp (epoch) in Sekunden - ursprüngliche 16 Stellen in Microsekunden
    my $currRev = $info->last_changed_rev();
    my $hash = md5_hex($targetPath); # Erzeuge Hash des db-Pfads
    #print "/".$dbTargetRoot."/".$targetPath, "\n";
    #print $hash, "\n";
    my $node = $svnChangeHistory->getElementById("_".$hash);
    unless(defined($node)) {
        $node = $svnChangeHistoryDocRoot->addNewChild( "","entry" );
        $node->setAttribute("xml:id", "_".$hash);
        $node->appendText($fullPath);
    }
    $node->setAttribute("author", $author);
    $node->setAttribute("dateTime", $dateTime->datetime()."Z");
    $node->setAttribute("rev", $currRev);
    #print $node->toString(), "\n";
    return 0;
}

# void modifyChangeEntry (string $fullSvnPath, string $targetPath, int $rev, ref svnClient)
sub modifyChangeEntry {
    print "Modifying change entry for $_[0]\n";
    my $fullSvnPath = $_[0];
    my $targetPath = $_[1];
    my $rev = $_[2];
    my $svnClient = ${$_[3]};
    my $infoReceiver = sub {
        my( $path, $info, $pool ) = @_;
        createChangeEntry($info, $targetPath);
        return 0;
    };
    $svnClient->info($fullSvnPath, $rev, $rev, $infoReceiver, 0);
    return 0;
}

# void removeChangeEntry (string $targetPath)
sub removeChangeEntry() {
    my $targetPath = $_[0];
    my $hash = md5_hex($targetPath);
    my $node = $svnChangeHistory->getElementById("_".$hash);
    if(defined($node)) {
        $svnChangeHistoryDocRoot->removeChild($node);
    }
    return 0;
}

# void saveToDb (string $svnPath, string $targetPath, int Revision?, ref svnClient)
sub saveToDb {
	#my $fullSvnPath = $repoPath."/".$_[0];
	my $svnPath = $_[0];
	my $targetPath = $_[1];
	my $revision = defined($_[2]) ? $_[2] : "HEAD"; 
	my $svnFile="";
	my $mimeType="";
	my $svnClient = ${$_[3]};
	open(MEMORY, ">", \$svnFile) or die "Can't open memory file: $!";
	$svnClient->cat2(\*MEMORY, $svnPath, $revision, $revision); # undocumented function allowing peg revisions, see http://stackoverflow.com/questions/6492192/how-can-i-use-peg-revisions-in-perl-svnclient
	#print $repoPath, "\n";
	
	if ($svnPath =~ m/\.jpe?g$/i){
		$mimeType = "image/jpeg";
		eXistStoreBinary($svnFile,$targetPath,$mimeType);
	}
	elsif ($svnPath =~ m/\.png$/i){
		$mimeType = "image/png";
		eXistStoreBinary($svnFile,$targetPath,$mimeType);
	}
	elsif ($svnPath =~ m/\.gif$/i){
		$mimeType = "image/gif";
		eXistStoreBinary($svnFile,$targetPath,$mimeType);
	}
	elsif ($svnPath =~ m/(\.xql)|(\.xqm)$/i){
		$mimeType = "application/xquery";
		eXistStoreBinary($svnFile,$targetPath,$mimeType);
	}
	elsif ($svnPath =~ m/\.js$/i){
		$mimeType = "text/javascript";
		eXistStoreBinary($svnFile,$targetPath,$mimeType);
	}
	elsif ($svnPath =~ m/\.css$/i){
		$mimeType = "text/css";
		eXistStoreBinary($svnFile,$targetPath,$mimeType);
	}
	elsif ($svnPath =~ m/\.php$/i){
		$mimeType = "application/x-httpd-php";
		eXistStoreBinary($svnFile,$targetPath,$mimeType);
	}
	elsif ($svnPath =~ m/\.eot$/i){
		$mimeType = "application/vnd.ms-fontobject";
		eXistStoreBinary($svnFile,$targetPath,$mimeType);
	}
	elsif ($svnPath =~ m/\.ico$/i){
		$mimeType = "image/x-icon";
		eXistStoreBinary($svnFile,$targetPath,$mimeType);
	}
	elsif ($svnPath =~ m/\.woff$/i){
		$mimeType = "application/x-woff";
		eXistStoreBinary($svnFile,$targetPath,$mimeType);
	}
	elsif ($svnPath =~ m/(\.xml)|(\.rng)|(\.xsl)|(\.xconf)|(\.html?)|(\.svg)$/i){
		eXistDbParse($svnFile,$targetPath);
	}
	else {
		printErrorLog("File due to suffix not taken into account: '$_[0]'");
	}
	close MEMORY || warn "close failed: $!";
	return 0;
}

sub eXistDbParse {
	if (defined($verbose)){print "Storing $_[1]\n"};
	my $req = RPC::XML::request->new("parse", RPC::XML::base64->new($_[0]), $_[1], 1);
	if (defined($overwrite)){
		my $resp = $rpcClient->send_request($req);
		if($resp->is_fault) {
			printErrorLog("Tried to add '$_[1]'",$resp->string);
		}
		else {if (defined($verbose)){print "Success\n"};}
	}
}

sub eXistDbRemove {
	if (defined($verbose)){print "Removing $_[0]\n"};
	my $req = RPC::XML::request->new("remove", $_[0]);
	if (defined($overwrite)){
		my $resp = $rpcClient->send_request($req);
		if($resp->is_fault) {
			printErrorLog("Tried to delete '$_[0]'",$resp->string);
		}
		else {if (defined($verbose)){print "Success\n"};}
	}
}

sub eXistDbCreateCollection {
	if (defined($verbose)){print "Creating $_[0]\n"};
	my $req = RPC::XML::request->new("createCollection", $_[0]);
	if (defined($overwrite)){
		my $resp = $rpcClient->send_request($req);
		if($resp->is_fault) {
			printErrorLog("Tried to create collection '$_[0]'",$resp->string);
		}
		else {if (defined($verbose)){print "Success\n"};}
	}
}

sub eXistDbRemoveCollection {
	if (defined($verbose)){print "Removing $_[0]\n"};
	my $req = RPC::XML::request->new("removeCollection", $_[0]);
	if (defined($overwrite)){
		my $resp = $rpcClient->send_request($req);
		if($resp->is_fault) {
			printErrorLog("Tried to remove collection '$_[0]'",$resp->string);
		}
		else {if (defined($verbose)){print "Success\n"};}
	}
}

# void eXistStoreBinary (string File, string TargetExistPath, string mimeType)
sub eXistStoreBinary {
	if (defined($verbose)){print "Storing $_[1]\n"};
	my $req = RPC::XML::request->new("storeBinary", RPC::XML::base64->new($_[0]), $_[1], $_[2], 1);
	if (defined($overwrite)){
		my $resp = $rpcClient->send_request($req);
		if($resp->is_fault) {
			printErrorLog("Tried to store binary file '$_[1]'",$resp->string);
		}
		else {if (defined($verbose)){print "Success\n"};}
	}
}

sub eXistGetDocumentAsString {
	if (defined($verbose)){print "Trying to fetch $_[0] ...\n"};
	my $req = RPC::XML::request->new("getDocumentAsString", $_[0], $_[1]);
	my $resp = $rpcClient->send_request($req);
	if($resp->is_fault) {
		printErrorLog("Tried to fetch '$_[0]'",$resp->string);
		die "Failed to reach eXist db or no file $_[0] found\n";
	}
	else {if (defined($verbose)){print "Success\n"};}
	return (encode('utf8', $resp->value));
}

# boolean setPermissions(String resource, String owner, String ownerGroup, int permissions)
sub eXistSetPermissions {
	if (defined($verbose)){print "Setting permissions on $_[0] ...\n"};
	my $req = RPC::XML::request->new("setPermissions", $_[0], $_[1], $_[2], $_[3]);
	if (defined($overwrite)){
       my $resp = $rpcClient->send_request($req);
       if($resp->is_fault) {
           printErrorLog("Failed to set permissions on '$_[0]'",$resp->string);
           die "Failed to reach eXist db or no file $_[0] found\n";
       }
       else {if (defined($verbose)){print "Success\n"};}
   }
	#return (encode('utf8', $resp->value));
}

# boolean reindexCollection(java.lang.String name)
sub eXistReindexCollection {
    my $collName = $_[0];
    if (defined($verbose)){print "Reindexing collection $collName ...\n"};
    my $req = RPC::XML::request->new("reindexCollection", $collName);
    my $resp = $rpcClient->send_request($req);
	if($resp->is_fault) {
		printErrorLog("Failed to reindex collection '$collName'",$resp->string);
		die "Failed to reach eXist db or no collection $_[0] found?!\n";
	}
	else {if (defined($verbose)){print "Success\n"};}
	#return (encode('utf8', $resp->value));
}

sub printErrorLog {
	open(FILE,">> $errorLogFile")
		or die "Could not write to log file $errorLogFile: $!\n";
	print FILE localtime()." ".$_[0];
	if (defined($verbose)){print $_[0]}
	if (defined($_[1])){
		print FILE ". RPC error was: '".$_[1]."'";
		if (defined($verbose)){print ". RPC error was: '".$_[1]."'";}
	}
	print FILE "\n";
	if (defined($verbose)){print "\n";}
	close(FILE) || warn "close failed: $errorLogFile!";
}
