include "base.thrift"
include "domain.thrift"

namespace java dev.vality.damsel.geo_ip
namespace erlang geo_ip

/**
* Идентификатор места по базе http://www.geonames.org/
**/
typedef i32 GeoID

/**
* GeoIsoCode - страна в формате ISO3166-1 Alpha 3
**/
typedef string GeoIsoCode

const GeoID GEO_ID_UNKNOWN = -1
const GeoIsoCode UNKNOWN = "UNKNOWN"

struct LocationInfo {
    // GeoID города
    1: required GeoID city_geo_id;
    // GeoID страны
    2: required GeoID country_geo_id;
    // Полное описание локации в json
    // подробное описание на сайте https://www.maxmind.com/en/geoip2-city
    3: optional string raw_response;
}
// Информация о регоине
struct SubdivisionInfo{
        // глубина в иерархии. Чем ниже тем цифра выше. Например 1 - Московская область. 2 - Подольский район.
       1: required i16 level
       2: required string subdivision_name;
}

/**
* Интерфейс Geo Service для клиентов - "Columbus"
*/
service GeoIpService {
    /**
    * Возвращает информацию о предполагаемом местоположении по IP
    * если IP некоректный то кидается InvalidRequest с этим IP
    * если для IP не найдена страна или город то в LocationInfo, данное поле будет иметь значение GEO_ID_UNKNOWN
    **/
    LocationInfo GetLocation (1: domain.IPAddress ip) throws (1: base.InvalidRequest ex1)

    /**
    *  то же что и GetLocation, но для списка IP адресов
    **/
    map <domain.IPAddress, LocationInfo> GetLocations (1: set <domain.IPAddress> ip) throws (1: base.InvalidRequest ex1)

    /**
    * Возвращает iso code страны местоположения по IP
    * если IP некоректный то кидается InvalidRequest с этим IP
    * если для IP не найдена iso code будет равен UNKNOWN
    **/
    GeoIsoCode GetLocationIsoCode (1: domain.IPAddress ip) throws (1: base.InvalidRequest ex1)
}