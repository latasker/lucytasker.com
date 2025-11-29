gallery_dir = config["gallery_dir"]
target_dir = config["target_dir"]
image_format = config["image_format"]
gallery_selector = config["selector"]

img_tmpl = [[
<div class="gallery-photo">
  <img src="%s" loading="lazy">
</div>
]]

gallery_elem = HTML.select_one(page, gallery_selector)

image_files = Sys.list_dir(gallery_dir)

-- Assume that all photos have names that start with a year,
-- like "YYYY some description"
function compare_photo_years(l, r)
  l_file = Sys.basename(l)
  r_file = Sys.basename(r)

  Log.debug(format("Comparing the dates of files: %s, %s", l_file, r_file))

  l_year = String.truncate_ascii(l_file, 4)
  r_year = String.truncate_ascii(r_file, 4)

  Log.debug(format("%s, %s", l_year, r_year))

  if l_year > r_year then return -1 end
  if l_year < r_year then return 1 end
  return 0
end

image_files = Table.sort(compare_photo_years, image_files)

function create_gallery_entry(source_file)
  if image_format then
    Log.debug(format("Processing image file %s", source_file))
    source_file_base = Sys.strip_extensions(Sys.basename(source_file))
    Log.debug(format("Running conversion command: convert '%s' '%s/%s.%s'",
                       source_file, Sys.join_path(build_dir, target_dir),
    source_file_base, image_format))
    Sys.run_program(format("convert '%s' '%s/%s.%s'",
                              source_file, Sys.join_path(build_dir, target_dir),
      source_file_base, image_format))
  end

  target_file = format("/%s/%s.%s", target_dir, source_file_base, image_format)
  img = format(img_tmpl, target_file)
  Log.debug(img)

  img_html = HTML.parse(img)
  HTML.append_child(gallery_elem, img_html)
end

Table.iter_values_ordered(create_gallery_entry, image_files)
