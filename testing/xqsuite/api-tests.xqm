xquery version "3.1";

module namespace at="http://weber-gesamtausgabe.de/xqsuite/api-tests";

declare namespace test="http://exist-db.org/xquery/xqsuite";

import module namespace api="http://xquery.weber-gesamtausgabe.de/modules/api" at "xmldb:exist:///db/apps/WeGA-WebApp/modules/api.xqm";

declare
    %test:assertEquals("1.0-draft")
    function at:test-reconciliation-manifest-version() as xs:string {
        api:reconciliation-manifest(map {
            'openapi:config': map {
                'servers': array { map { 'url': 'https://weber-gesamtausgabe.de/api/v1' } }
            }
        })?results?versions?1
};

declare
    %test:assertEquals(4)
    function at:test-reconciliation-manifest-types() as xs:integer {
        count(api:reconciliation-manifest(map {
            'openapi:config': map {
                'servers': array { map { 'url': 'https://weber-gesamtausgabe.de/api/v1' } }
            }
        })?results?defaultTypes?*)
};

declare
    %test:assertEquals("https://weber-gesamtausgabe.de/{id}")
    function at:test-reconciliation-manifest-view() as xs:string {
        api:reconciliation-manifest(map {
            'openapi:config': map {
                'servers': array { map { 'url': 'https://weber-gesamtausgabe.de/api/v1' } }
            }
        })?results?view?url
};

declare
    %test:assertEquals("A002332")
    function at:test-reconciliation-suggest-entity-id-prefix() as xs:string? {
        api:reconciliation-suggest-entity(map {
            'prefix': 'A002332',
            'openapi:config': map {
                'servers': array { map { 'url': 'https://weber-gesamtausgabe.de/api/v1' } }
            }
        })?results?result?1?id
};
