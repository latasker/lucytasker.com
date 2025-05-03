Log.debug(JSON.pretty_print(config))

data_file = config["data_file"]
template = config["template"]

Log.debug(format("Loading gig data from file %s", data_file))

toml_source = Sys.read_file(config["data_file"])
Log.debug(toml_source)

toml_data = TOML.from_string(toml_source)

Log.debug(JSON.pretty_print(toml_data))

gig_list = toml_data["gigs"]

Log.debug(JSON.pretty_print(gig_list))

-- Comparison function that returns results
-- as sort functions expect them (-1, 0, 1)
-- in ascending order
function compare(l, r)
  if (l > r) then
    return 1
  end

  if (l == r) then
    return 0
  end

  return -1
end

function compare_gig_dates_ascending(l, r)
  l = Date.to_timestamp(l["date"], {"%Y-%m-%d"})
  r = Date.to_timestamp(r["date"], {"%Y-%m-%d"})
  return compare(l, r)
end

function compare_gig_dates_descending(l, r)
  l = Date.to_timestamp(l["date"], {"%Y-%m-%d"})
  r = Date.to_timestamp(r["date"], {"%Y-%m-%d"})
  return compare(r, l)
end

function is_upcoming_gig(g)
  now = Date.now_timestamp()
  gig_date = Date.to_timestamp(g["date"], {"%Y-%m-%d"})

  if gig_date > now then
    return 1
  else
    return nil
  end
end

function is_past_gig(g)
  return (not is_upcoming_gig(g))
end

Log.debug(JSON.pretty_print(gig_list))
Log.debug("filtering gigs...")

upcoming_gigs = Table.find_values(is_upcoming_gig, gig_list)
past_gigs = Table.find_values(is_past_gig, gig_list)

Log.debug("sorting gigs...")

-- 
upcoming_gigs = Caml.List.sort(compare_gig_dates_ascending, upcoming_gigs)
past_gigs = Caml.List.sort(compare_gig_dates_descending, past_gigs)

Log.debug(JSON.pretty_print(upcoming_gigs))

env = {}
env["upcoming_gigs"] = upcoming_gigs
env["past_gigs"] = past_gigs
gigs_html_source = String.render_template(template, env)

Log.debug(gigs_html_source)

container = HTML.select_one(page, config["selector"])

HTML.append_child(container, HTML.parse(gigs_html_source))
