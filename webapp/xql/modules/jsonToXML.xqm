xquery version "1.0" encoding "UTF-8";
module namespace jsonToXML="http://xqilla.sourceforge.net/Functions";
(:----------------------------------------------------------------------------------------------------:)
(: JSON parsing :)

declare function jsonToXML:parse-json($json as xs:string) as element()? {
  let $res := jsonToXML:parseValue(jsonToXML:tokenize($json))
  return
    if(exists(remove($res,1))) then jsonToXML:parseError($res[2])
    else element json {
      $res[1]/@*,
      $res[1]/node()
    }
};

declare function jsonToXML:parseValue($tokens as element(token)*)
{
  let $token := $tokens[1]
  let $tokens := remove($tokens,1)
  return
    if($token/@t = "lbrace") then (
      let $res := jsonToXML:parseObject($tokens)
      let $tokens := remove($res,1)
      return (
        element res {
          attribute type { "object" },
          $res[1]/node()
        },
        $tokens
      )
    ) else if ($token/@t = "lsquare") then (
      let $res := jsonToXML:parseArray($tokens)
      let $tokens := remove($res,1)
      return (
        element res {
          attribute type { "array" },
          $res[1]/node()
        },
        $tokens
      )
    ) else if ($token/@t = "number") then (
      element res {
        attribute type { "number" },
        text { $token }
      },
      $tokens
    ) else if ($token/@t = "string") then (
      element res {
        attribute type { "string" },
        text { jsonToXML:unescape-json-string($token) }
      },
      $tokens
    ) else if ($token/@t = "true" or $token/@t = "false") then (
      element res {
        attribute type { "boolean" },
        text { $token }
      },
      $tokens
    ) else if ($token/@t = "null") then (
      element res {
        attribute type { "null" }
      },
      $tokens
    ) else jsonToXML:parseError($token)
};

declare function jsonToXML:parseObject($tokens as element(token)*)
{
  let $token1 := $tokens[1]
  let $tokens := remove($tokens,1)
  return
    if(not($token1/@t = "string")) then jsonToXML:parseError($token1) else
      let $token2 := $tokens[1]
      let $tokens := remove($tokens,1)
      return
        if(not($token2/@t = "colon")) then jsonToXML:parseError($token2) else
          let $res := jsonToXML:parseValue($tokens)
          let $tokens := remove($res,1)
          let $pair := element pair {
            attribute name { $token1 },
            $res[1]/@*,
            $res[1]/node()
          }
          let $token := $tokens[1]
          let $tokens := remove($tokens,1)
          return
            if($token/@t = "comma") then (
              let $res := jsonToXML:parseObject($tokens)
              let $tokens := remove($res,1)
              return (
                element res {
                  $pair,
                  $res[1]/node()
                },
                $tokens
              )
            ) else if($token/@t = "rbrace") then (
              element res {
                $pair
              },
              $tokens
            ) else jsonToXML:parseError($token)
};

declare function jsonToXML:parseArray($tokens as element(token)*)
{
  let $res := jsonToXML:parseValue($tokens)
  let $tokens := remove($res,1)
  let $item := element item {
    $res[1]/@*,
    $res[1]/node()
  }
  let $token := $tokens[1]
  let $tokens := remove($tokens,1)
  return
    if($token/@t = "comma") then (
      let $res := jsonToXML:parseArray($tokens)
      let $tokens := remove($res,1)
      return (
        element res {
          $item,
          $res[1]/node()
        },
        $tokens
      )
    ) else if($token/@t = "rsquare") then (
      element res {
        $item
      },
      $tokens
    ) else jsonToXML:parseError($token)
};

declare function jsonToXML:parseError($token as element(token)) as empty-sequence() {
  error(xs:QName("jsonToXML:PARSEJSON01"),
    concat("Unexpected token: ", string($token/@t), " (""", string($token), """)"))
};

declare function jsonToXML:tokenize($json as xs:string) as element(token)*
{
  let $tokens := ("\{", "\}", "\[", "\]", ":", ",", "true", "false", "null", "\s+",
    '"([^"\\]|\\"|\\\\|\\/|\\b|\\f|\\n|\\r|\\t|\\u[A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9])*"',
    "-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?")
  let $regex := string-join(for $t in $tokens return concat("(",$t,")"),"|")
  for $match in jsonToXML:analyze-string($json, $regex, 14)
  return
    if($match/self::non-match) then jsonToXML:token("error", string($match))
    else if($match//group/@nr = 1) then jsonToXML:token("lbrace", string($match))
    else if($match//group/@nr = 2) then jsonToXML:token("rbrace", string($match))
    else if($match//group/@nr = 3) then jsonToXML:token("lsquare", string($match))
    else if($match//group/@nr = 4) then jsonToXML:token("rsquare", string($match))
    else if($match//group/@nr = 5) then jsonToXML:token("colon", string($match))
    else if($match//group/@nr = 6) then jsonToXML:token("comma", string($match))
    else if($match//group/@nr = 7) then jsonToXML:token("true", string($match))
    else if($match//group/@nr = 8) then jsonToXML:token("false", string($match))
    else if($match//group/@nr = 9) then jsonToXML:token("null", string($match))
    else if($match//group/@nr = 10) then () (: ignore whitespace :)
    else if($match//group/@nr = 11) then (: Strings in JSON :)
      let $v := string($match)
      let $len := string-length($v)
      return jsonToXML:token("string", substring($v, 2, $len - 2))
    else if($match//group/@nr = 13) then jsonToXML:token("number", string($match)) (: Numbers in JSON :)
    else ()(:jsonToXML:token("error", string($match)):)
};

declare function jsonToXML:token($t, $value)
{
  <token t="{$t}">{ string($value) }</token>
};

(:----------------------------------------------------------------------------------------------------:)
(: JSON unescaping :)

declare function jsonToXML:unescape-json-string($val as xs:string) as xs:string
{
  let $tmp := normalize-space(util:unescape-uri($val,"UTF-8"))
  return replace($val,"\\f","&#x0A;")
  (:
  string-join(
    let $regex := '([^\\]+)|(\\")|(\\\\)|(\\/)|(\\b)|(\\f)|(\\n)|(\\r)|(\\t)|(\\u[A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9])'
    for $match in jsonToXML:analyze-string($val, $regex, 10)
    return
      if($match//group/@nr = 1) then """"
      else if($match//group/@nr = 2) then "\"
      else if($match//group/@nr = 3) then "/"
      (: else if($match/*:group/@nr = 4) then "&#x08;" :)
      (: else if($match/*:group/@nr = 5) then "&#x0C;" :)
      else if($match//group/@nr = 6) then "&#x0A;"
      else if($match//group/@nr = 7) then "&#x0D;"
      else if($match//group/@nr = 8) then "&#x09;"
      else if($match//group/@nr = 9) then codepoints-to-string(jsonToXML:decode-hex-string(substring($match, 3)))
      else string($match)
  ,"")
  :)
};

declare function jsonToXML:decode-hex-string($val as xs:string)
  as xs:integer
{
  jsonToXML:decodeHexStringHelper(string-to-codepoints($val), 0)
};

declare function jsonToXML:decodeHexChar($val as xs:integer)
  as xs:integer
{
  let $tmp := $val - 48 (: '0' :)
  let $tmp := if($tmp <= 9) then $tmp else $tmp - (65-48) (: 'A'-'0' :)
  let $tmp := if($tmp <= 15) then $tmp else $tmp - (97-65) (: 'a'-'A' :)
  return $tmp
};

declare function jsonToXML:decodeHexStringHelper($chars as xs:integer*, $acc as xs:integer)
  as xs:integer
{
  if(empty($chars)) then $acc
  else jsonToXML:decodeHexStringHelper(remove($chars,1), ($acc * 16) + jsonToXML:decodeHexChar($chars[1]))
};

declare function jsonToXML:analyze-string($string as xs:string, $regex as xs:string, $n as xs:integer) {
transform:transform   
   (<any/>, 
   <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0"> 
      <xsl:param name="myRegex" as="xs:string"/>
      <xsl:param name="myString" as="xs:string"/>
      <xsl:template match='/' >  
         <xsl:analyze-string regex="&#123;$myRegex&#125;" select="$myString" > 
            <xsl:matching-substring>
               <xsl:for-each select="1 to {$n}"> 
                  <xsl:if test="regex-group(.)!=''">
                  		<group>
   							<xsl:attribute name="nr" select="."/> 
                    	   	<xsl:value-of select="regex-group(.)"/>
                   		</group>  
					</xsl:if>
                </xsl:for-each>
             </xsl:matching-substring> 
         </xsl:analyze-string>
      </xsl:template>
   </xsl:stylesheet>,
   <parameters><param name="myRegex" value="{$regex}"/><param name="myString" value="{$string}"/></parameters>
   )
};