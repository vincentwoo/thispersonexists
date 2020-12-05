require 'json'
require 'dotenv/load'
require 'http'
require 'pp'

json = JSON.parse(File.read('ffhq-dataset-v2.json'))

skip_to_idx = 0
written_idx = 0

json.each.with_index do |(key, image), idx|
  next if idx < skip_to_idx
  puts "idx: #{idx}, written_idx: #{written_idx}"
  sleep 1
  begin
    flickr_url = image['metadata']['photo_url']
    photo_id = flickr_url.split('/').last
    dimensions = image['in_the_wild']['pixel_size']

    response = HTTP.get('https://www.flickr.com/services/rest/',
      params: {
        method: 'flickr.photos.getSizes',
        api_key: ENV['FLICKR_API_KEY'],
        photo_id: photo_id,
        format: 'json',
        nojsoncallback: 1
    })
    response = JSON.parse(response.to_s)
    size = response['sizes']['size'].find { |size| [size['width'], size['height']] == dimensions }

    File.write("data/#{written_idx}.json", {
      flickr_url: flickr_url,
      photo_url: size['source'],
      author: image['metadata']['author'],
      # face_rect: image['in_the_wild']['face_rect'],
      face_quad: image['in_the_wild']['face_quad']
    }.to_json)
    written_idx += 1
  rescue
    # pass
  end
end
