/*
 * Copyright (c) 2019 Matteo Baccan
 * https://www.baccan.it
 *
 * Distributed under the GPL v3 software license, see the accompanying
 * file LICENSE or http://www.gnu.org/licenses/gpl.html.
 *
 */
/**
 * JWT Implementation
 *
 * https://datatracker.ietf.org/doc/html/rfc7519
 *
 */

 //Source located at https://github.com/matteobaccan/HarbourJwt/blob/main/src/jwt.prg
 // Minor tweaks Eric Lendvai


#include "hbclass.ch"

CLASS JWT

HIDDEN:

  CLASSDATA cSecret
  CLASSDATA aHeader
  CLASSDATA aPayload
  CLASSDATA cError

  METHOD Base64UrlEncode( cData )
  METHOD Base64UrlDecode( cData )
  METHOD ByteToString( cData )
  METHOD GetSignature( cHeader, cPayload, cSecret, cAlgorithm )
  METHOD CheckPayload(aPayload, cKey)

EXPORTED:

  METHOD New() CONSTRUCTOR

  // Header
  METHOD SetType( cType )
  METHOD GetType()                          INLINE ::aHeader[ 'typ' ]
  METHOD SetContentType( cContentType )     INLINE ::aHeader[ 'cty' ] :=  cContentType
  METHOD GetContentType()                   INLINE ::aHeader[ 'cty' ]
  METHOD SetAlgorithm( cAlgorithm )
  METHOD GetAlgorithm()                     INLINE ::aHeader[ 'alg' ]

  // Payload
  METHOD SetIssuer( cIssuer )               INLINE ::SetPayloadData('iss', cIssuer)
  METHOD GetIssuer()                        INLINE ::GetPayloadData('iss')
  METHOD SetSubject( cSubject )             INLINE ::SetPayloadData('sub', cSubject)
  METHOD GetSubject()                       INLINE ::GetPayloadData('sub')
  METHOD SetAudience( cAudience )           INLINE ::SetPayloadData('aud', cAudience)
  METHOD GetAudience()                      INLINE ::GetPayloadData('aud')
  METHOD SetExpration( nExpiration )        INLINE ::SetPayloadData('exp', nExpiration)
  METHOD GetExpration()                     INLINE ::GetPayloadData('exp')
  METHOD SetNotBefore( nNotBefore )         INLINE ::SetPayloadData('nbf', nNotBefore)
  METHOD GetNotBefore()                     INLINE ::GetPayloadData('nbf')
  METHOD SetIssuedAt( nIssuedAt )           INLINE ::SetPayloadData('iat', nIssuedAt)
  METHOD GetIssuedAt()                      INLINE ::GetPayloadData('iat')
  METHOD SetJWTId( cJWTId )                 INLINE ::SetPayloadData('jti', cJWTId)
  METHOD GetJWTId()                         INLINE ::GetPayloadData('jti')

  // Payload methods
  METHOD SetPayloadData( cKey, uValue )     INLINE IF( uValue==NIL, hb_HDel(::aPayload,cKey), ::aPayload[cKey] := uValue)
  METHOD GetPayloadData( cKey )             INLINE IF( hb_HHasKey(::aPayLoad,cKey), ::aPayload[cKey], NIL )

  // Secret
  METHOD SetSecret( cSecret )               INLINE ::cSecret := cSecret
  METHOD GetSecret()                        INLINE ::cSecret

  // Error
  METHOD GetError()                         INLINE ::cError

  // Cleanup: aHeader, aPayload, cError, cSecret
  METHOD Reset()

  // Encode a JWT and return it
  METHOD Encode()

  // Decode a JWT
  METHOD Decode( cJWT )

  // Decode a JWT
  METHOD Verify( cJWT )

  // Getter internal data with internal exposion
  METHOD GetPayload()                       INLINE hb_hClone(::aPayload)
  METHOD GetHeader()                        INLINE hb_hClone(::aHeader)

  // Helper method for expiration setting
  METHOD GetSeconds()

  // Versione
  METHOD GetVersion()                       INLINE "1.0.2"

ENDCLASS

METHOD New() CLASS JWT
  ::Reset()
return SELF

// Optional
METHOD SetType( cType ) CLASS JWT
  LOCAL bRet := .F.

  IF cType=="JWT"
      ::aHeader[ 'typ' ] := cType
  ELSE
      bRet := .F.
      ::cError := "Invalid type [" +cType +"]"
  ENDIF

return bRet

// Mandatory
METHOD SetAlgorithm( cAlgorithm ) CLASS JWT
  LOCAL bRet := .F.

  IF cAlgorithm=="HS256" .OR. cAlgorithm=="HS384" .OR. cAlgorithm=="HS512"
      ::aHeader[ 'alg' ] := cAlgorithm
  ELSE
      bRet := .F.
      ::cError := "Invalid algorithm [" +cAlgorithm +"]"
  ENDIF

return bRet

METHOD Reset() CLASS JWT

  ::aHeader   := {=>}
  ::aPayload := {=>}
  ::cError  := ''
  ::cSecret  := ''

return NIL


METHOD Encode() CLASS JWT

  LOCAL cHeader
  LOCAL cPayload
  LOCAL cSignature

  //  Encode header
  cHeader     := ::Base64UrlEncode( hb_jsonEncode( ::aHeader ) )

  // Encode payload
  cPayload    := ::Base64UrlEncode( hb_jsonEncode( ::aPayload ) )

  //  Make signature
  cSignature := ::GetSignature( cHeader, cPayload, ::cSecret, ::aHeader[ 'alg' ] )

//  Return JWT
return cHeader + '.' + cPayload + '.' + cSignature

METHOD Base64UrlEncode( cData ) CLASS JWT
return hb_StrReplace( hb_base64Encode( cData ), "+/=", { "-", "_", "" } )

METHOD Base64UrlDecode( cData ) CLASS JWT
return hb_base64Decode( hb_StrReplace( cData, "-_", "+/" ) )

METHOD ByteToString( cData ) CLASS JWT
   LOCAL cRet := SPACE(LEN(cData)/2)
   LOCAL nLen := LEN( cData )
   LOCAL nX, nNum

   cData := UPPER(cData)
   FOR nX := 1 TO nLen STEP 2
      nNum := ( AT( SubStr( cData, nX  , 1 ), "0123456789ABCDEF" ) - 1 ) * 16
      nNum += AT( SubStr( cData, nX+1, 1 ), "0123456789ABCDEF" ) - 1
      HB_BPOKE( @cRet, (nX+1)/2, nNum )
   NEXT

return cRet

METHOD GetSignature( cHeader, cPayload, cSecret, cAlgorithm ) CLASS JWT
  LOCAL cSignature := ""

  DO CASE
     CASE cAlgorithm=="HS256"
         cSignature := ::Base64UrlEncode( ::ByteToString( HB_HMAC_SHA256( cHeader + '.' + cPayload, cSecret ) ) )
     CASE cAlgorithm=="HS384"
         cSignature := ::Base64UrlEncode( ::ByteToString( HB_HMAC_SHA384( cHeader + '.' + cPayload, cSecret ) ) )
     CASE cAlgorithm=="HS512"
         cSignature := ::Base64UrlEncode( ::ByteToString( HB_HMAC_SHA512( cHeader + '.' + cPayload, cSecret ) ) )
     OTHERWISE
         ::cError := "INVALID ALGORITHM"
  ENDCASE
return cSignature

METHOD Decode( cJWT ) CLASS JWT

  LOCAL aJWT

  // Reset Object
  ::Reset()

  // Check JWT
  IF VALTYPE(cJWT)!="C"
      ::cError := "Invalid JWT: not character ["+VALTYPE(cJWT)+"]"
      return .F.
  ENDIF

  //  Split JWT
  aJWT := HB_ATokens( cJWT, '.' )
  IF LEN(aJWT) <> 3
      ::cError := "Invalid JWT"
      return .F.
  ENDIF

  // Explode header
  ::aHeader   := hb_jsonDecode( ::Base64UrlDecode( aJWT[1] ))

  // Exploce payload
  ::aPayload  := hb_jsonDecode( ::Base64UrlDecode( aJWT[2] ))

return .T.

METHOD Verify( cJWT ) CLASS JWT

  LOCAL aJWT, aHeader, aPayload
  LOCAL cSignature, cNewSignature

  // Check JWT
  IF VALTYPE(cJWT)!="C"
      ::cError := "Invalid JWT: not character ["+VALTYPE(cJWT)+"]"
      return .F.
  ENDIF

  //  Split JWT
  aJWT := HB_ATokens( cJWT, '.' )
  IF LEN(aJWT) <> 3
      ::cError := "Invalid JWT"
      return .F.
  ENDIF

  // Explode header
  aHeader   := hb_jsonDecode( ::Base64UrlDecode( aJWT[1] ))

  // Check aHeader
  IF VALTYPE(aHeader)!="H"
      ::cError := "Invalid JWT: header not base64"
      return .F.
  ENDIF

  // Exploce payload
  aPayload   := hb_jsonDecode( ::Base64UrlDecode( aJWT[2] ))

  // Check aPayload
  IF VALTYPE(aPayload)!="H"
      ::cError := "Invalid JWT: payload not base64"
      return .F.
  ENDIF

  // Get signature
  cSignature  := aJWT[3]

  // Calculate new sicnature
  cNewSignature   := ::GetSignature( aJWT[1], aJWT[2], ::cSecret, aHeader[ 'alg' ] )
  IF ( cSignature != cNewSignature )
    ::cError := "Invalid signature"
    return .F.
  ENDIF

  // Check Issuer
  IF !::CheckPayload(aPayload, 'iss')
     ::cError := "Different issuer"
     return .F.
  ENDIF

  // Check Subject
  IF !::CheckPayload(aPayload, 'sub')
     ::cError := "Different subject"
     return .F.
  ENDIF

  // Check Audience
  IF !::CheckPayload(aPayload, 'aud')
     ::cError := "Different audience"
     return .F.
  ENDIF

  // Check expiration
  IF hb_HHasKey(aPayLoad,'exp')
     IF aPayLoad[ 'exp' ] < ::GetSeconds()
       ::cError := "Token expired"
       return .F.
     ENDIF
  ENDIF

  // Check not before
  IF hb_HHasKey(aPayLoad,'nbf')
     IF aPayLoad[ 'nbf' ] > ::GetSeconds()
       ::cError := "Token not valid until:" +STR(aPayLoad[ 'nbf' ])
       return .F.
     ENDIF
  ENDIF

  // Check issuedAt
  IF hb_HHasKey(aPayLoad,'iat')
     IF aPayLoad[ 'iat' ] > ::GetSeconds()
       ::cError := "Token issued in future:" +STR(aPayLoad[ 'iat' ])
       return .F.
     ENDIF
  ENDIF

  // Check JWT id
  IF !::CheckPayload(aPayload, 'jti')
     ::cError := "Different JWT id"
     return .F.
  ENDIF

  // Check Type
  IF !::CheckPayload(aPayload, 'typ')
     ::cError := "Different JWT type"
     return .F.
  ENDIF

return .T.

METHOD GetSeconds() CLASS JWT

  LOCAL posixday := date() - STOD("19700101")
  LOCAL cTime := time()
  LOCAL posixsec := posixday * 24 * 60 * 60

return posixsec + (int(val(substr(cTime,1,2))) * 3600) + (int(val(substr(cTime,4.2))) * 60) + ( int(val(substr(cTime,7,2))) )

METHOD CheckPayload(aPayload, cKey) CLASS JWT
  IF hb_HHasKey(aPayLoad,cKey) .AND. hb_HHasKey(::aPayLoad,cKey)
     IF aPayLoad[ cKey ] != ::aPayLoad[ cKey ]
       return .F.
     ENDIF
  ELSEIF hb_HHasKey(aPayLoad,cKey) .OR. hb_HHasKey(::aPayLoad,cKey)
     return .F.
  ENDIF
return .T.
