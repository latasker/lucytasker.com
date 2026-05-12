gallery_dir = config["gallery_dir"]
target_dir = config["target_dir"]
image_format = config["image_format"]
gallery_selector = config["selector"]
preview_width = config["preview_width"]

img_tmpl = [[
<div class="gallery-photo">
  <img src="%s" loading="lazy">
</div>
]]

gallery_elem = HTML.select_one(page, gallery_selector)

image_files = Sys.list_dir(gallery_dir)

function get_file_timestamp(file)
  if Regex.match(file, "^\\d{4}-\\d{2}-\\d{2}.*") then
    Log.debug(format("File name %s contains a full YYYY-MM-DD timestamp", file))
    date = String.truncate_ascii(file, 10)
    return Date.to_timestamp(date, {"%Y-%m-%d"})
  end

  if Regex.match(file, "^\\d{4}.*") then
    Log.debug(format("File name %s contains a year, assuming YYYY-01-01", file))
    date = String.truncate_ascii(file, 4)
    return Date.to_timestamp(date, {"%Y"})
  end

  -- If all else failed
  Log.warning(format("File name %s does not start with a YYYY-MM-DD date or a year prefix", file))
  return 0
end

-- Assume that all photos have names that start with a year,
-- like "YYYY some description"
function compare_photo_years(l, r)
  l_file = Sys.basename(l)
  r_file = Sys.basename(r)

  Log.debug(format("Comparing the dates of files: %s, %s", l_file, r_file))

  l_timestamp = get_file_timestamp(l_file)
  r_timestamp =	get_file_timestamp(r_file)

  if l_timestamp > r_timestamp then return -1 end
  if l_timestamp < r_timestamp then return 1 end
  return 0
end

image_files = Table.sort(compare_photo_years, image_files)

function create_gallery_entry(source_file)
  if image_format then
    Log.debug(format("Processing image file %s", source_file))
    source_file_base = Sys.strip_extensions(Sys.basename(source_file))
    resize_option = ""
    if config["preview_width"] then
      resize_option = format("-resize %s", config["preview_width"])
    end
    command = format("convert %s '%s' '%s/%s.%s'",
                     resize_option, source_file, Sys.join_path(build_dir, target_dir),
                     source_file_base, image_format)
    Log.debug(format("Running conversion command: %s", command))
    Sys.run_program(command)
  end

  target_file = format("/%s/%s.%s", target_dir, source_file_base, image_format)
  img = format(img_tmpl, target_file)
  Log.debug(img)

  img_html = HTML.parse(img)
  HTML.append_child(gallery_elem, img_html)
end

Table.iter_values_ordered(create_gallery_entry, image_files)
