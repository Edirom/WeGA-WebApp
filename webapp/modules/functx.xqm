xquery version "1.0" encoding "UTF-8";
module namespace  functx = "http://www.functx.com" ;
declare default collation "?lang=de;strength=primary";

(:~

 : --------------------------------
 : The FunctX XQuery Function Library
 : --------------------------------

 : Copyright (C) 2007 Datypic

 : This library is free software; you can redistribute it and/or
 : modify it under the terms of the GNU Lesser General Public
 : License as published by the Free Software Foundation; either
 : version 2.1 of the License.

 : This library is distributed in the hope that it will be useful,
 : but WITHOUT ANY WARRANTY; without even the implied warranty of
 : MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 : Lesser General Public License for more details.

 : You should have received a copy of the GNU Lesser General Public
 : License along with this library; if not, write to the Free Software
 : Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

 : For more information on the FunctX XQuery library, contact contrib@functx.com.

 : @version 1.0
 : @see     http://www.xqueryfunctions.com
 :)

(:~
 : Performs multiple replacements, using pairs of replace parameters 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_replace-multi.html 
 : @param   $arg the string to manipulate 
 : @param   $changeFrom the sequence of strings or patterns to change from 
 : @param   $changeTo the sequence of strings to change to 
 :) 
declare function functx:replace-multi 
  ( $arg as xs:string? ,
    $changeFrom as xs:string* ,
    $changeTo as xs:string* )  as xs:string? {
       
   if (count($changeFrom) > 0)
   then functx:replace-multi(
          replace($arg, $changeFrom[1],
                     functx:if-absent($changeTo[1],'')),
          $changeFrom[position() > 1],
          $changeTo[position() > 1])
   else $arg
 } ;

(:~
 : The first argument if it is not empty, otherwise the second argument 
 :
 : @author  W3C XML Query WG 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_if-absent.html 
 : @param   $arg the item(s) that may be absent 
 : @param   $value the item(s) to use if the item is absent 
 :) 
declare function functx:if-absent 
  ( $arg as item()* ,
    $value as item()* )  as item()* {
       
    if (exists($arg))
    then $arg
    else $value
 } ;

(:~
 : The substring after the last text that matches a regex 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_substring-after-last-match.html 
 : @param   $arg the string to substring 
 : @param   $regex the regular expression 
 :) 
declare function functx:substring-after-last-match 
  ( $arg as xs:string? ,
    $regex as xs:string )  as xs:string {
       
   replace($arg,concat('^.*',$regex),'')
 } ;

(:~
 : The substring after the last occurrence of a delimiter 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_substring-after-last.html 
 : @param   $arg the string to substring 
 : @param   $delim the delimiter 
 :) 
declare function functx:substring-after-last 
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {
       
   replace ($arg,concat('^.*',functx:escape-for-regex($delim)),'')
 } ;

(:~
 : Escapes regex special characters 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_escape-for-regex.html 
 : @param   $arg the string to escape 
 :) 
declare function functx:escape-for-regex 
  ( $arg as xs:string? )  as xs:string {
       
   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;

(:~
 : The substring after the first text that matches a regex 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_substring-before-last-match.html 
 : @param   $arg the string to substring 
 : @param   $regex the regular expression 
 :) 
declare function functx:substring-before-last-match 
  ( $arg as xs:string? ,
    $regex as xs:string )  as xs:string? {
       
   replace($arg,concat('^(.*)',$regex,'.*'),'$1')
 } ;

(:~
 : The substring before the last occurrence of a delimiter 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_substring-before-last.html 
 : @param   $arg the string to substring 
 : @param   $delim the delimiter 
 :) 
declare function functx:substring-before-last 
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {
       
   if (matches($arg, functx:escape-for-regex($delim)))
   then replace($arg,
            concat('^(.*)', functx:escape-for-regex($delim),'.*'),
            '$1')
   else ''
 } ;

(:~
 : The substring before the last text that matches a regex 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_substring-before-match.html 
 : @param   $arg the string to substring 
 : @param   $regex the regular expression 
 :) 
declare function functx:substring-before-match 
  ( $arg as xs:string? ,
    $regex as xs:string )  as xs:string {
       
   tokenize($arg,$regex)[1]
 } ;

(:~
 : The union of two sequences of values 
 :
 : @author  W3C XML Query Working Group 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_value-union.html 
 : @param   $arg1 the first sequence 
 : @param   $arg2 the second sequence 
 :) 
declare function functx:value-union 
  ( $arg1 as xs:anyAtomicType* ,
    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {
       
  distinct-values(($arg1, $arg2))
 } ;

(:~
 : Pads an integer to a desired length by adding leading zeros 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_pad-integer-to-length.html 
 : @param   $integerToPad the integer to pad 
 : @param   $length the desired length 
 :) 
declare function functx:pad-integer-to-length 
  ( $integerToPad as xs:anyAtomicType? ,
    $length as xs:integer )  as xs:string {
       
   if ($length < string-length(string($integerToPad)))
   then error(xs:QName('functx:Integer_Longer_Than_Length'))
   else concat
         (functx:repeat-string(
            '0',$length - string-length(string($integerToPad))),
          string($integerToPad))
 } ;

(:~
 : Repeats a string a given number of times 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_repeat-string.html 
 : @param   $stringToRepeat the string to repeat 
 : @param   $count the desired number of copies 
 :) 
declare function functx:repeat-string 
  ( $stringToRepeat as xs:string? ,
    $count as xs:integer )  as xs:string {
       
   string-join((for $i in 1 to $count return $stringToRepeat),
                        '')
 } ;


(:~
 : Whether a value is all whitespace or a zero-length string 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_all-whitespace.html 
 : @param   $arg the string (or node) to test 
 :) 
declare function functx:all-whitespace 
  ( $arg as xs:string? )  as xs:boolean {
       
   normalize-space($arg) = ''
 } ;

(:~
 : Splits a string into matching and non-matching regions 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_get-matches-and-non-matches.html 
 : @param   $string the string to split 
 : @param   $regex the pattern 
 :) 
declare function functx:get-matches-and-non-matches 
  ( $string as xs:string? ,
    $regex as xs:string )  as element()* {
       
   let $iomf := functx:index-of-match-first($string, $regex)
   return
   if (empty($iomf))
   then <non-match>{$string}</non-match>
   else
   if ($iomf > 1)
   then (<non-match>{substring($string,1,$iomf - 1)}</non-match>,
         functx:get-matches-and-non-matches(
            substring($string,$iomf),$regex))
   else
   let $length :=
      string-length($string) -
      string-length(functx:replace-first($string, $regex,''))
   return (<match>{substring($string,1,$length)}</match>,
           if (string-length($string) > $length)
           then functx:get-matches-and-non-matches(
              substring($string,$length + 1),$regex)
           else ())
 } ;

(:~
 : Return the matching regions of a string 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_get-matches.html 
 : @param   $string the string to split 
 : @param   $regex the pattern 
 :) 
declare function functx:get-matches 
  ( $string as xs:string? ,
    $regex as xs:string )  as xs:string* {
       
   functx:get-matches-and-non-matches($string,$regex)/
     string(self::match)
 } ;

(:~
 : Replaces the first match of a pattern 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_replace-first.html 
 : @param   $arg the entire string to change 
 : @param   $pattern the pattern of characters to replace 
 : @param   $replacement the replacement string 
 :) 
declare function functx:replace-first 
  ( $arg as xs:string? ,
    $pattern as xs:string ,
    $replacement as xs:string )  as xs:string {
       
   replace($arg, concat('(^.*?)', $pattern),
             concat('$1',$replacement))
 } ;

(:~
 : The first position of a matching substring 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_index-of-match-first.html 
 : @param   $arg the string 
 : @param   $pattern the pattern to match 
 :) 
declare function functx:index-of-match-first 
  ( $arg as xs:string? ,
    $pattern as xs:string )  as xs:integer? {
       
  if (matches($arg,$pattern))
  then string-length(tokenize($arg, $pattern)[1]) + 1
  else ()
 } ;

(:~
 : The position of a node in a sequence, based on node identity 
 :
 : @author  W3C XML Query Working Group 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_index-of-node.html 
 : @param   $nodes the node sequence 
 : @param   $nodeToFind the node to find in the sequence 
 :) 
declare function functx:index-of-node 
  ( $nodes as node()* ,
    $nodeToFind as node() )  as xs:integer* {
       
  for $seq in (1 to count($nodes))
  return $seq[$nodes[$seq] is $nodeToFind]
 } ;

(:~
 : The distinct XML nodes in a sequence (by node identity) 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_distinct-nodes.html 
 : @param   $nodes the node sequence 
 :) 
declare function functx:distinct-nodes 
  ( $nodes as node()* )  as node()* {
       
    for $seq in (1 to count($nodes))
    return $nodes[$seq][not(functx:is-node-in-sequence(
                                .,$nodes[position() < $seq]))]
 } ;


(:~
 : Whether an XML node is in a sequence, based on node identity 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_is-node-in-sequence.html 
 : @param   $node the node to test 
 : @param   $seq the sequence of nodes to search 
 :) 
declare function functx:is-node-in-sequence 
  ( $node as node()? ,
    $seq as node()* )  as xs:boolean {
       
   some $nodeInSeq in $seq satisfies $nodeInSeq is $node
 } ;


(:~
 : The XML nodes with distinct values, taking into account attributes and descendants 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_distinct-deep.html 
 : @param   $nodes the sequence of nodes to test 
 :) 
declare function functx:distinct-deep 
  ( $nodes as node()* )  as node()* {
       
    for $seq in (1 to count($nodes))
    return $nodes[$seq][not(functx:is-node-in-sequence-deep-equal(
                          .,$nodes[position() < $seq]))]
 } ;


(:~
 : Whether an XML node is in a sequence, based on contents and attributes 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_is-node-in-sequence-deep-equal.html 
 : @param   $node the node to test 
 : @param   $seq the sequence of nodes to search 
 :) 
declare function functx:is-node-in-sequence-deep-equal 
  ( $node as node()? ,
    $seq as node()* )  as xs:boolean {
       
   some $nodeInSeq in $seq satisfies deep-equal($nodeInSeq,$node)
 } ;

(:~
 : Whether an element has empty content 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_has-empty-content.html 
 : @param   $element the XML element to test 
 :) 
declare function functx:has-empty-content 
  ( $element as element() )  as xs:boolean {
       
   not($element/node())
 } ;

(:~
 : The position of a node in a sequence, based on contents and attributes 
 :
 : @author  Priscilla Walmsley, Datypic 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_index-of-deep-equal-node.html 
 : @param   $nodes the node sequence 
 : @param   $nodeToFind the node to find in the sequence 
 :) 
declare function functx:index-of-deep-equal-node 
  ( $nodes as node()* ,
    $nodeToFind as node() )  as xs:integer* {
       
  for $seq in (1 to count($nodes))
  return $seq[deep-equal($nodes[$seq],$nodeToFind)]
 } ;

(:~
 : The intersection of two sequences of values 
 :
 : @author  W3C XML Query Working Group 
 : @version 1.0 
 : @see     http://www.xqueryfunctions.com/xq/functx_value-intersect.html 
 : @param   $arg1 the first sequence 
 : @param   $arg2 the second sequence 
 :) 
declare function functx:value-intersect 
  ( $arg1 as xs:anyAtomicType* ,
    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {
       
  distinct-values($arg1[.=$arg2])
 } ;