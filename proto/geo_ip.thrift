include "base.thrift"
include "domain.thrift"

// moved to https://github.com/valitydev/columbus-proto

namespace java dev.vality.damsel.columbus
namespace erlang columbus

/**
* Идентификатор места по базе http://www.geonames.org/
**/
typedef i32 GeoID

const GeoID GEO_ID_UNKNOWN = -1

struct LocationInfo {
    // GeoID города
    1: required GeoID city_geo_id;
    // GeoID страны
    2: required GeoID country_geo_id;
    // Полное описание локации в json
    // подробное описание на сайте https://www.maxmind.com/en/geoip2-city
    3: optional string raw_response;
}