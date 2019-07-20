#' @title Get non-aggregated data from your AppMetrica application
#' @description This function allows you to obtain raw data from your AppMetrica application. The AppMetrica Logs API accepts the request and puts it in the queue. If the request is processed successfully, AppMetrica prepares a file for download. In this case, the API returns the HTTP 202 Accepted status. If the request resulted in an error, the API returns the appropriate response status, and the HTTP message body contains the error description.
#' @param type API resources
#' @param application_id 	Unique numeric identifier for the application in AppMetrica
#' @param date_since Start of the date range in the yyyy-mm-dd hh:mm:ss format
#' @param date_until End of the date range in the yyyy-mm-dd hh:mm:ss format
#' @param date_dimension The parameter defines what date and time are used as a condition for getting into the data sample. default вЂ” When the event occurred on the device; receive вЂ” When the server received event information.
#' @param fields A comma-separated list of fields for the sample
#' @param token An access token from the Yandex.OAuth service
#' @return The requested data will be returned as a data frame.
#' @export
#' @examples
#' \dontrun{
#' get_appmetrica_logs (type = 'installations',
#' application_id = 130000,
#' date_since = '2019-05-01',
#' date_until = '2019-05-31',
#' fields = 'install_datetime,publisher_name,tracker_name,appmetrica_device_id,click_url_parameters,is_reinstallation'
#' )
#'}

get_appmetrica_logs <- function(
  type = "installations",
  application_id = NULL,
  date_since = "2018-01-01",
  date_until = "2018-01-02",
  date_dimension = "default",
  fields = "install_datetime,appmetrica_device_id,is_reinstallation",
  token = NULL
){
  if (is.null(token)) {
    token <- appmetrica_auth()
  }

  request_status <- 0

  while (request_status != 200) {
    request <- GET(url = paste0("https://api.appmetrica.yandex.ru/logs/v1/export/", type, ".csv"),
                   query = list(
                     application_id = application_id,
                     date_since = date_since,
                     date_until = date_until,
                     date_dimension = date_dimension,
                     fields = gsub("[\\s\\n\\t]", "", fields, perl = TRUE)
                   ),
                   add_headers(Authorization = paste0("OAuth ", token)))

    if (http_error(request)) {
      stop(content(request))
    }

    request_status <- status_code(request)

    if (request_status == 202) {
      suppressMessages(content(request))
    }

    Sys.sleep(10)

    message("Waiting for data")

  }

  result <- content(request, as = "parsed", "text/csv")

  return(result)

}

#' @title Get data from your AppMetrica application
#' @description The Reporting API allows you to get application traffic statistics and other data without using the AppMetrica interface. You can create the desired report structure by specifying metrics and dimensions in the API request.
#' @param ids Comma-separated list of counter numbers.
#' @param date1 Start date of the report period in the format YYYY-MM-DD. You can also use the values: today, yesterday, ndaysAgo. Default value: 6daysAgo
#' @param date2 End date of the report period in the format YYYY-MM-DD. You can also use the values: today, yesterday, ndaysAgo. Default value: today
#' @param metrics Comma-separated list of metrics. Limit: 20 metrics per request.
#' @param dimensions 	Comma-separated list of dimensions. Limit: 10 dimensions per request.
#' @param filters Segmentation filter. Limit: Maximum of 10 unique dimensions and metrics, 20 separate filters, and 10,000 characters per filter string.
#' @param group Grouping data by time. Default value: week
#' @param accuracy Accuracy of results. Allows you to manage sampling (the number of visits used to calculate the final value). Default value: full
#' @param include_undefined Outputs rows that don't have defined dimension values. This only affects the first dimension. Disabled by default.
#' @param lang Language.
#' @param token An access token from the Yandex.OAuth service
#' @return The requested data will be returned as a data frame.
#' @export
#' @examples
#' \dontrun{
#' get_appmetrica_data (
#' ids = "130830,130825",
#' date1 = "2018-01-01",
#' date2 = "2018-02-02",
#' metrics = "ym:ge:users",
#' dimensions = "ym:ge:mobileDeviceBranding,ym:ge:mobileDeviceModel,ym:ge:appID,ym:ge:date"
#' )
#'}

get_appmetrica_data <- function(
  ids = NULL,
  date1 = NULL,
  date2 = NULL,
  metrics = "ym:ge:users",
  dimensions = "ym:ge:appID",
  filters = NULL,
  group = NULL,
  accuracy = "full",
  include_undefined = NULL,
  lang = NULL,
  token = NULL
){

  if (is.null(token)) {
    token <- appmetrica_auth()
  }

  #check if query has an error
  request <- GET(url = "https://api.appmetrica.yandex.ru/stat/v1/data",
                 query = list(
                   ids = ids,
                   date1 = date1,
                   date2 = date2,
                   metrics = gsub("[\\s\\n\\t]", "", metrics, perl = TRUE),
                   dimensions = gsub("[\\s\\n\\t]", "", dimensions, perl = TRUE),
                   filters = filters,
                   group = group,
                   accuracy = "full",
                   include_undefined = include_undefined,
                   lang = tolower(lang),
                   limit = 1
                 ),
                 add_headers(Authorization = paste0("OAuth ", token)))

  answer <- content(request, type = "application/json")

  if (http_error(request)) {
    stop(answer$message)
  }

  limit    <- 99998
  offset   <- 1

  rows_in_sample <- 1

  list_of_samples <- list()
  counter <- 1

  #collect samples until we run out of rows in a sample
  while (rows_in_sample > 0) {
    request <- GET(url = "https://api.appmetrica.yandex.ru/stat/v1/data.csv",
                   query = list(
                     ids = ids,
                     date1 = date1,
                     date2 = date2,
                     metrics = gsub("[\\s\\n\\t]", "", metrics, perl = TRUE),
                     dimensions = gsub("[\\s\\n\\t]", "", dimensions, perl = TRUE),
                     filters = filters,
                     group = group,
                     accuracy = "full",
                     include_undefined = include_undefined,
                     lang = tolower(lang),
                     limit = limit,
                     offset = offset
                   ),
                   add_headers(Authorization = paste0("OAuth ", token)))

    answer <- suppressMessages(content(request, as = "parsed", "text/csv")[-1, ])

    rows_in_sample <- nrow(answer)
    offset <- limit + offset

    # add data to list_of_samples if we have avaliable rows
    if (rows_in_sample > 0) {
      list_of_samples[[counter]] <- answer
      counter <- counter + 1
    }

  }

  final_df <- do.call("rbind", list_of_samples)

  return(final_df)
}


appmetrica_auth <- function(token.path = getwd()) {

  if (!dir.exists(token.path)) {
    dir.create(token.path)
  }

  if (file.exists(paste0(token.path, "/", ".appmetricaToken.RData"))) {

    message("Load token from ", paste0(token.path, "/", ".appmetricaToken.RData"))
    load(paste0(token.path, "/", ".appmetricaToken.RData"))

    return(token)
  }

  browseURL("https://oauth.yandex.ru/authorize?response_type=token&client_id=fbb25fdcc6764e52b7181dc043d40b54")

  token <- readline(prompt = "Enter authorize code:")

  message("Do you want to save token in local file (", paste0(token.path, "/", ".appmetricaToken.RData"), "),?")
  ans <- readline("y / n (recomedation - y): ")

  if (tolower(ans) %in% c("y", "yes", "ok", "save")) {
    save(token, file = paste0(token.path, "/",  ".appmetricaToken.RData"))
    message("Token saved in file ", paste0(token.path, "/", ".appmetricaToken.RData"))
  }

  return(token)

}
