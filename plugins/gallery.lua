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

function compare_photo_years(l, r)
  l_file = Sys.basename(l)
  r_file = Sys.basename(r)

  l_year = String.truncate_ascii(l_file, 4)
  r_year = String.truncate_ascii(r_file, 4)

  if l_year > r_year then return -1 end
  if l_year < r_year then return 1 end
  return 0
end

image_files = Table.sort(compare_photo_years, image_files)

function create_gallery_entry(source_file)
  if image_format then
    source_file_base = Sys.strip_extensions(Sys.basename(source_file))
    Sys.run_program(format("magick convert '%s' '%s/%s.%s'", source_file, Sys.join_path(build_dir, target_dir), source_file_base, image_format))
  end

  target_file = format("/%s/%s.%s", target_dir, source_file_base, image_format)
  img = format(img_tmpl, target_file)

  img_html = HTML.parse(img)
  HTML.append_child(gallery_elem, img_html)
end

Table.iter_values_ordered(create_gallery_entry, image_files)
