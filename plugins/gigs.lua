-- Generates a page with events from a TOML date file.
-- Events are automatically split into upcoming and past
-- and can be rendered using a template.
--
-- Author: Daniil Baturin
-- License: MIT

Plugin.require_version("5.0.0")

---- Helper functions

-- Comparison function for Table.sort
function compare(l, r)
  if (l > r) then
    return 1
  end

  if (l == r) then
    return 0
  end

  return -1
end

function add_event_timestamp(event)
  date = event["date"]

  if not date then
    Plugin.fail(format("Event is missing required field \"date\". Event data:\n%s",
      JSON.pretty_print(event)))
  end

  res = Date.to_timestamp(date, date_formats)

  if (not res) then
    Plugin.fail(format("Date string \"%s\" doesn't match any of the configured formats", date))
  else
    event["timestamp"] = res
  end
end

function compare_dates_ascending(l, r)
  return compare(l["timestamp"], r["timestamp"])
end

function compare_dates_descending(l, r)
  return compare_dates_ascending(r, l)
end

-- Record the current timestamp
-- and store it so that every date comparison is done with the same timestamp
-- (if the plugin starts executing just before midnight,
--  comparisons may be executed on different dates,
--  which would produce strange results).
now = Date.now_timestamp()

function is_upcoming(event)
  if event["timestamp"] > now then
    return 1
  else
    return nil
  end
end

function is_past(event)
  return (not is_upcoming(event))
end

---- Main logic 

-- Retrieve and validate configuration options

-- [REQUIRED] The file with event data, in TOML
data_file = config["data_file"]
if not Value.is_string(data_file) then
  Plugin.fail("The option \"data_file\" must be set to a string")
end

-- [REQUIRED] The key to take from the data
-- It must hold an array of tables
key = config["key"]
if not Value.is_string(key) then
  Plugin.fail("The option \"key\" must be set to a string")
end

-- [REQUIRED] The Jingoo template source code used for rendering
-- the list of events into HTML
template = config["template"]
if not Value.is_string(template) then
  Plugin.fail("The option \"template\" must be set to a string")
end

-- [OPTIONAL] Supported date input formats for event date
-- Defaults to ISO 8601 (YYYY-MM-DD)
date_formats = config["date_formats"]
if not date_formats then
  Log.info("date_formats is not specified, using default (YYYY-MM-DD)")
  date_formats = {"%Y-%m-%d"}
end

if not Value.is_list(date_formats) then
  if Value.is_string(date_formats) then
    date_formats = {date_formats}
  else
    Plugin.fail("date_formats should be a string or a list of strings")
  end
end

-- [OPTIONAL] Date output format
-- If present, all event dates are converted to it
-- If not, the original date from the source file is displayed
date_display_format = config["date_display_format"]
Log.debug(format("Display date format: %s", date_display_format))

-- [OPTIONAL] Maximum number of past events
past_events_limit = config["past_events_limit"]
if past_events_limit then
  if not Value.is_int(past_events_limit) then
    Plugin.fail("The option \"past_events_limit\" must be an integer")
  end
end 

-- Load event data

Log.debug(format("Loading event data from file %s", data_file))

toml_source = Sys.read_file(config["data_file"])
toml_data = TOML.from_string(toml_source)

events = toml_data[key]

-- Parse event dates and add timestamps to event objects
Table.iter_values(add_event_timestamp, events)

function set_date(event)
  if date_display_format then
    Log.debug("Reformatting")
    event["date"] = Date.reformat(event["date"], date_formats, date_display_format)
  end
end
Table.iter_values(set_date, events)

-- Split the list into lists of upcoming and past events
upcoming_events = Table.find_values(is_upcoming, events)
past_events = Table.find_values(is_past, events)

-- Upcoming events are sorted from nearest to farthest in the future
-- Past events are sorted from the most recent to the most distant in the past
upcoming_gigs = Table.sort(compare_dates_ascending, upcoming_events)
past_gigs = Table.sort(compare_dates_descending, past_events)

-- Truncate the list of past events, if a limit is configured
if past_events_limit then
  past_events = Table.take(past_events, past_events_limit)
end

-- Prepare the template environment
env = {}
env["upcoming_events"] = upcoming_events
env["past_events"] = past_events

-- Render the list of events as HTML using the template
events_html = String.render_template(template, env)

-- Insert the generated HTML into the page
container = HTML.select_one(page, config["selector"])
HTML.append_child(container, HTML.parse(events_html))
