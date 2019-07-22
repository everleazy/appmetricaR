# appmetricaR
The package for working with AppMetrica data. The Logs API and the Reporting API are available.

## Installation
You can simply install the appmetricaR just typing:
```r
devtools::install_github("SergeiMakarovWeb/appmetricaR")
```
## Authorization
In order to use the AppMetrica API, you need to get an access token from the Yandex.OAuth service. You can get your own token by following instructions here and then use it in function’s body. Or you can skip obtaining the OAuth token and the appmetricaR will generate it for you. You will be able to save the token locally and then reuse it in your next requests.

## Usage

[Reporting API](https://appmetrica.yandex.ru/docs/mobile-api/api_v1/intro.html)

In order to obtain data from the Reporting API use the function get_appmetrica_data. 
```r
df <- get_appmetrica_data (ids = 100000,
                           date1 = "2019-01-01",
                           date2 = "yesterday",
                           metrics = "ym:i:installDevices",
                           dimensions = "ym:i:publisher,ym:i:campaign")
                    
# Example with filters and several counters
df <- get_appmetrica_data (ids = "100000,100001",
                           date1 = "2019-01-01",
                           date2 = "yesterday",
                           metrics = "ym:i:installDevices",
                           dimensions = "ym:i:publisher,ym:i:campaign",
                           filters = "ym:ge:regionCityName=='Москва'")
```
[Logs API](https://appmetrica.yandex.ru/docs/mobile-api/logs/about.html)

In order to obtain raw data from the Logs API use the function get_appmetrica_logs.
```r
df <- get_appmetrica_logs (type = 'installations',
                           application_id = 100000,
                           date_since = "2019-04-01",
                           date_until = "2019-05-02",
                           fields = 'install_datetime, publisher_name, appmetrica_device_id')
```
