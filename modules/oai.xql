xquery version "3.1" encoding "UTF-8";

(:~
 :  OAI-PMH 2.0 interface for the HHA data
 :  @see https://www.openarchives.org/OAI/openarchivesprotocol.html
 :
 :  Central endpoint (/oai) dispatching on the "verb" request parameter:
 :  Identify, ListMetadataFormats, ListSets, GetRecord, ListIdentifiers, ListRecords.
 :
 :  Records whose file consists of a single tei:ref[@type = ('duplicate','deletion')]
 :  redirect (see crud:doc()) are exposed as OAI-PMH deleted records (header/@status="deleted").
 :)

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace oai="http://www.openarchives.org/OAI/2.0/";

import module namespace functx="http://www.functx.com";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace lod="http://xquery.weber-gesamtausgabe.de/modules/lod" at "lod.xqm";

declare option output:method "xml";
declare option output:media-type "application/xml";
declare option output:indent "yes";

declare variable $oai:metadata-prefix as xs:string := 'oai_dc';
declare variable $oai:granularity as xs:string := 'YYYY-MM-DDThh:mm:ssZ';
declare variable $oai:base-url as xs:string := config:get-option('permaLinkPrefix') || '/oai';
declare variable $oai:list-size as xs:integer :=
    let $opt := config:get-option('oaiListSize')
    return if($opt castable as xs:integer) then xs:integer($opt) else 25;

(:~
 : The OAI "sets" exposed by this repository: one set per HHA document type.
 : @see config:get-doctype-by-id()
:)
declare variable $oai:sets := (
    map { 'spec': 'persons', 'name': 'Personen' },
    map { 'spec': 'characters', 'name': 'Fiktive und mythologische Figuren' },
    map { 'spec': 'orgs', 'name': 'Institutionen' },
    map { 'spec': 'places', 'name': 'Orte' },
    map { 'spec': 'letters', 'name': 'Briefe' },
    map { 'spec': 'diaries', 'name': 'Tagebücher' },
    map { 'spec': 'writings', 'name': 'Schriften' },
    map { 'spec': 'news', 'name': 'Zeitungsmeldungen' },
    map { 'spec': 'works', 'name': 'Werke' },
    map { 'spec': 'sources', 'name': 'Quellen' },
    map { 'spec': 'documents', 'name': 'Dokumente' },
    map { 'spec': 'iconography', 'name': 'Ikonographie' },
    map { 'spec': 'biblio', 'name': 'Bibliographie' },
    map { 'spec': 'thematicCommentaries', 'name': 'Werkkommentare' },
    map { 'spec': 'corresp', 'name': 'Korrespondenzstellen' },
    map { 'spec': 'addenda', 'name': 'Addenda' },
    map { 'spec': 'var', 'name': 'Varia' }
);

(: ============================== helpers ============================== :)

declare %private function oai:param($name as xs:string) as xs:string? {
    request:get-parameter($name, ())[1]
};

declare %private function oai:known-params() as xs:string* {
    request:get-parameter-names()[. ne 'verb']
};

declare %private function oai:permalink($docID as xs:string) as xs:string {
    config:permalink($docID)
};

declare %private function oai:format-datetime($dt as xs:dateTime) as xs:string {
    let $utc := adjust-dateTime-to-timezone($dt, xs:dayTimeDuration('PT0S'))
    return format-dateTime($utc, '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]Z')
};

(:~
 : Get the last date of modification from dataHistory.xml. Fallback: current dateTime
 : @author Dennis Ried
 : @param $docID The ID of the document
 : @return The date as xs:dateTime
:)
declare %private function oai:last-modified($docID as xs:string) as xs:dateTime {
    let $props := config:get-svn-props($docID)
    return
        if($props?dateTime castable as xs:dateTime)
        then ($props?dateTime => xs:dateTime())
        else (fn:current-dateTime())
};

(:~
 : A conservative earliest datestamp for Identify: the inception date of the
 : change-history tracking. Guaranteed to be <= any real record datestamp.
:)
declare %private function oai:earliest-datestamp() as xs:dateTime {
    if($config:svn-change-history-file/dictionary/@dateTime castable as xs:dateTime)
    then xs:dateTime($config:svn-change-history-file/dictionary/@dateTime)
    else fn:current-dateTime()
};

(:~
 : Determines whether a document is a redirect stub and, if so, of which kind.
 : Untyped tei:ref redirects (transparently resolved by crud:doc()) are internal
 : aliases and yield (); "duplicate"/"deletion" refs mark an OAI deleted record.
:)
declare %private function oai:redirect-type($doc as document-node()?) as xs:string? {
    let $ref := $doc/*/*:ref[1]
    return
        if(empty($ref)) then ()
        else if($ref/@type) then string($ref/@type)
        else 'redirect'
};

declare %private function oai:resolve-identifier($identifier as xs:string?) as xs:string? {
    let $docID := if($identifier) then functx:substring-after-last($identifier, '/') else ()
    return if($docID and config:get-doctype-by-id($docID)) then $docID else ()
};

declare %private function oai:is-valid-datetime-param($value as xs:string?) as xs:boolean {
    empty($value) or $value eq ''
    or matches($value, '^\d{4}-\d{2}-\d{2}$')
    or matches($value, '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$')
};

declare %private function oai:parse-datetime-param($value as xs:string?, $endOfDay as xs:boolean) as xs:dateTime? {
    if(empty($value) or $value eq '') then ()
    else if(matches($value, '^\d{4}-\d{2}-\d{2}$'))
    then xs:dateTime($value || (if($endOfDay) then 'T23:59:59Z' else 'T00:00:00Z'))
    else xs:dateTime($value)
};

declare %private function oai:error($code as xs:string, $message as xs:string) as element(oai:error) {
    <error xmlns="http://www.openarchives.org/OAI/2.0/" code="{$code}">{$message}</error>
};

(:~
 : Validates that only $allowed request parameters (besides "verb") were given
 : and that all $required parameters are present.
:)
declare %private function oai:validate-params($allowed as xs:string*, $required as xs:string*) as element(oai:error)? {
    let $given := oai:known-params()
    let $unknown := $given[not(. = $allowed)]
    let $missing := $required[not(. = $given)]
    return
        if(exists($unknown)) then oai:error('badArgument', 'Illegal argument(s) for this verb: ' || string-join($unknown, ', '))
        else if(exists($missing)) then oai:error('badArgument', 'Missing required argument(s): ' || string-join($missing, ', '))
        else ()
};

(: ============================== Identify ============================== :)

declare %private function oai:identify() as element(oai:Identify) {
    <Identify xmlns="http://www.openarchives.org/OAI/2.0/">
        <repositoryName>{config:get-option('oaiRepositoryName')}</repositoryName>
        <baseURL>{$oai:base-url}</baseURL>
        <protocolVersion>2.0</protocolVersion>
        <adminEmail>{config:get-option('oaiAdminEmail')}</adminEmail>
        <earliestDatestamp>{oai:format-datetime(oai:earliest-datestamp())}</earliestDatestamp>
        <deletedRecord>persistent</deletedRecord>
        <granularity>{$oai:granularity}</granularity>
    </Identify>
};

(: ========================= ListMetadataFormats ========================= :)

declare %private function oai:list-metadata-formats() as element()* {
    let $identifier := oai:param('identifier')
    return
        if(exists($identifier) and empty(oai:resolve-identifier($identifier)))
        then oai:error('idDoesNotExist', 'No record found for identifier "' || $identifier || '".')
        else
            <ListMetadataFormats xmlns="http://www.openarchives.org/OAI/2.0/">
                <metadataFormat>
                    <metadataPrefix>oai_dc</metadataPrefix>
                    <schema>http://www.openarchives.org/OAI/2.0/oai_dc.xsd</schema>
                    <metadataNamespace>http://www.openarchives.org/OAI/2.0/oai_dc/</metadataNamespace>
                </metadataFormat>
            </ListMetadataFormats>
};

(: ============================== ListSets =============================== :)

declare %private function oai:list-sets() as element(oai:ListSets) {
    <ListSets xmlns="http://www.openarchives.org/OAI/2.0/">
        {
            for $s in $oai:sets
            order by $s?spec
            return
                <set>
                    <setSpec>{$s?spec}</setSpec>
                    <setName>{$s?name}</setName>
                </set>
        }
    </ListSets>
};

(: =========================== record building ============================ :)

declare %private function oai:doc-id($doc as document-node()) as xs:string {
    string($doc/*/@xml:id)
};

declare %private function oai:record-header($docID as xs:string, $docType as xs:string, $lastMod as xs:dateTime, $deleted as xs:boolean) as element(oai:header) {
    <header xmlns="http://www.openarchives.org/OAI/2.0/">
        {if($deleted) then attribute status {'deleted'} else ()}
        <identifier>{oai:permalink($docID)}</identifier>
        <datestamp>{oai:format-datetime($lastMod)}</datestamp>
        <setSpec>{$docType}</setSpec>
    </header>
};

declare %private function oai:record-metadata($docID as xs:string, $doc as document-node(), $docType as xs:string, $lastMod as xs:dateTime, $lang as xs:string) as element(oai:metadata) {
    let $model := map { 'docID': $docID, 'doc': $doc, 'docType': $docType, 'lang': $lang }
    let $dc := lod:metadata(<node/>, $model, $lang)
    let $dc-date := oai:format-datetime($lastMod) => substring(1, 10)
    return
        <metadata xmlns="http://www.openarchives.org/OAI/2.0/">
            <oai_dc:dc
                xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
                <dc:title>{$dc?meta-page-title}</dc:title>
                <dc:creator>{$dc?DC.creator}</dc:creator>
                <dc:subject>{$dc?DC.subject}</dc:subject>
                <dc:description>{$dc?DC.description}</dc:description>
                <dc:date>{$dc-date}</dc:date>
                <dc:identifier>{$dc?DC.identifier}</dc:identifier>
            </oai_dc:dc>
        </metadata>
};

declare %private function oai:build-record($docID as xs:string, $doc as document-node()?, $docType as xs:string, $lastMod as xs:dateTime, $lang as xs:string, $withMetadata as xs:boolean) as element(oai:record) {
    let $deleted := oai:redirect-type($doc) = ('duplicate', 'deletion')
    return
        <record xmlns="http://www.openarchives.org/OAI/2.0/">
            {oai:record-header($docID, $docType, $lastMod, $deleted)}
            {if($withMetadata and not($deleted)) then oai:record-metadata($docID, $doc, $docType, $lastMod, $lang) else ()}
        </record>
};

(: ============================== GetRecord =============================== :)

declare %private function oai:get-record($lang as xs:string, $identifier as xs:string?, $metadataPrefix as xs:string?) as element()* {
    if(empty($identifier) or empty($metadataPrefix))
    then oai:error('badArgument', 'Required arguments "identifier" and "metadataPrefix" are missing.')
    else if($metadataPrefix ne $oai:metadata-prefix)
    then oai:error('cannotDisseminateFormat', 'Metadata format "' || $metadataPrefix || '" is not supported.')
    else
        let $docID := oai:resolve-identifier($identifier)
        return
            if(empty($docID))
            then oai:error('idDoesNotExist', 'No record found for identifier "' || $identifier || '".')
            else
                let $doc := crud:doc($docID)
                let $docType := config:get-doctype-by-id($docID)
                let $lastMod := oai:last-modified($docID)
                return
                    <GetRecord xmlns="http://www.openarchives.org/OAI/2.0/">
                        {oai:build-record($docID, $doc, $docType, $lastMod, $lang, true())}
                    </GetRecord>
};

(: ==================== ListIdentifiers / ListRecords ======================= :)

(:~
 : Assembles one page of a ListIdentifiers/ListRecords result and, if more
 : records remain, a resumptionToken encoding (set, from, until, nextOffset).
:)
declare %private function oai:list-page($verb as xs:string, $lang as xs:string, $set as xs:string?, $from as xs:dateTime?, $until as xs:dateTime?, $offset as xs:integer) as element()* {
    let $validSet := empty($set) or $set = ($oai:sets ! ?spec)
    return
        if(not($validSet))
        then oai:error('noRecordsMatch', 'The combination of the given arguments results in an empty list.')
        else
            let $setSpecs := if(exists($set)) then $set else ($oai:sets ! ?spec)
            let $candidates :=
                for $spec in $setSpecs
                for $doc in crud:data-collection($spec)
                let $redirectType := oai:redirect-type($doc)
                where empty($redirectType) or $redirectType ne 'redirect'
                let $docID := oai:doc-id($doc)
                let $lastMod := oai:last-modified($docID)
                where (empty($from) or $lastMod ge $from) and (empty($until) or $lastMod le $until)
                order by $docID
                return map { 'docID': $docID, 'doc': $doc, 'docType': $spec, 'lastMod': $lastMod }
            let $total := count($candidates)
            return
                if($total eq 0)
                then oai:error('noRecordsMatch', 'The combination of the given arguments results in an empty list.')
                else if($offset ge $total)
                then oai:error('badResumptionToken', 'The resumption token is invalid or expired.')
                else
                    let $page := subsequence($candidates, $offset + 1, $oai:list-size)
                    let $nextOffset := $offset + $oai:list-size
                    let $resumption :=
                        <resumptionToken xmlns="http://www.openarchives.org/OAI/2.0/" cursor="{$offset}" completeListSize="{$total}">
                        {
                            if($nextOffset lt $total)
                            then string-join((
                                    ($set, '')[1],
                                    (($from ! oai:format-datetime(.)), '')[1],
                                    (($until ! oai:format-datetime(.)), '')[1],
                                    string($nextOffset)
                                ), '~')
                            else ()
                        }
                        </resumptionToken>
                    return
                        element { QName('http://www.openarchives.org/OAI/2.0/', $verb) } {
                            (
                                for $c in $page
                                return oai:build-record($c?docID, $c?doc, $c?docType, $c?lastMod, $lang, $verb eq 'ListRecords'),
                                $resumption
                            )
                        }
};

declare %private function oai:resume-list($verb as xs:string, $lang as xs:string, $token as xs:string) as element()* {
    try {
        let $parts := tokenize($token, '~')
        return
            if(count($parts) ne 4 or not($parts[4] castable as xs:integer))
            then oai:error('badResumptionToken', 'The resumption token is invalid or expired.')
            else
                let $set := if($parts[1] eq '') then () else $parts[1]
                let $from := if($parts[2] eq '') then () else xs:dateTime($parts[2])
                let $until := if($parts[3] eq '') then () else xs:dateTime($parts[3])
                let $offset := xs:integer($parts[4])
                return oai:list-page($verb, $lang, $set, $from, $until, $offset)
    } catch * {
        oai:error('badResumptionToken', 'The resumption token is invalid or expired.')
    }
};

declare %private function oai:list-records-or-identifiers($verb as xs:string, $lang as xs:string) as element()* {
    let $resumptionToken := oai:param('resumptionToken')
    return
        if(exists($resumptionToken)) then
            let $err := oai:validate-params(('resumptionToken'), ('resumptionToken'))
            return if($err) then $err else oai:resume-list($verb, $lang, $resumptionToken)
        else
            let $err := oai:validate-params(('metadataPrefix', 'from', 'until', 'set'), ('metadataPrefix'))
            return
                if($err) then $err
                else
                    let $metadataPrefix := oai:param('metadataPrefix')
                    return
                        if($metadataPrefix ne $oai:metadata-prefix)
                        then oai:error('cannotDisseminateFormat', 'Metadata format "' || $metadataPrefix || '" is not supported.')
                        else
                            let $set := oai:param('set')
                            let $fromParam := oai:param('from')
                            let $untilParam := oai:param('until')
                            return
                                if(not(oai:is-valid-datetime-param($fromParam)) or not(oai:is-valid-datetime-param($untilParam)))
                                then oai:error('badArgument', 'Arguments "from"/"until" must be of the form YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ.')
                                else
                                    let $from := oai:parse-datetime-param($fromParam, false())
                                    let $until := oai:parse-datetime-param($untilParam, true())
                                    return
                                        if(exists($from) and exists($until) and $from gt $until)
                                        then oai:error('badArgument', 'Argument "from" must not be later than argument "until".')
                                        else oai:list-page($verb, $lang, $set, $from, $until, 0)
};

(: ============================== dispatch ================================= :)

declare %private function oai:dispatch($lang as xs:string) as element()+ {
    let $verbs := ('Identify', 'ListMetadataFormats', 'ListSets', 'GetRecord', 'ListIdentifiers', 'ListRecords')
    let $verbParams := request:get-parameter('verb', ())
    return
        if(count($verbParams) ne 1 or not($verbParams = $verbs))
        then oai:error('badVerb', 'Illegal, missing, or repeated verb argument.')
        else
            let $verb := $verbParams[1]
            return
                switch($verb)
                case 'Identify' return
                    let $err := oai:validate-params((), ())
                    return if($err) then $err else oai:identify()
                case 'ListMetadataFormats' return
                    let $err := oai:validate-params(('identifier'), ())
                    return if($err) then $err else oai:list-metadata-formats()
                case 'ListSets' return
                    let $err := oai:validate-params((), ())
                    return if($err) then $err else oai:list-sets()
                case 'GetRecord' return
                    let $err := oai:validate-params(('identifier', 'metadataPrefix'), ('identifier', 'metadataPrefix'))
                    return if($err) then $err else oai:get-record($lang, oai:param('identifier'), oai:param('metadataPrefix'))
                case 'ListIdentifiers' return oai:list-records-or-identifiers('ListIdentifiers', $lang)
                case 'ListRecords' return oai:list-records-or-identifiers('ListRecords', $lang)
                default return oai:error('badVerb', 'Illegal, missing, or repeated verb argument.')
};

(:~
 : Echoes the request as required by the spec: base URL plus the (valid) verb
 : and arguments given - or just the base URL if the verb itself was illegal.
:)
declare %private function oai:request-element($result as element()*) as element(oai:request) {
    let $isBadVerb := exists($result/self::oai:error[@code eq 'badVerb'])
    return
        <request xmlns="http://www.openarchives.org/OAI/2.0/">
            {
                if($isBadVerb) then ()
                else (
                    attribute verb { oai:param('verb') },
                    for $name in oai:known-params()
                    return attribute {$name} { oai:param($name) }
                )
            }
            {$oai:base-url}
        </request>
};

declare %private function oai:response-envelope($result as element()*) as element(oai:OAI-PMH) {
    <OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
        <responseDate>{oai:format-datetime(fn:current-dateTime())}</responseDate>
        {oai:request-element($result)}
        {$result}
    </OAI-PMH>
};

(: ================================ main ==================================== :)

let $lang := config:guess-language(())
return (
    response:set-header('Access-Control-Allow-Origin', '*'),
    response:set-header('Cache-Control', 'max-age=300,public'),
    oai:response-envelope(oai:dispatch($lang))
)
