require 'json'
require 'dotenv/load'
require 'http'
require 'pp'

json = JSON.parse(File.open('ffhq-dataset-v2.json').read)

skip_to_idx = 10279 # 0
written_idx = 9555 # 0

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

    File.open("data/#{written_idx}.json", 'w') do |f|
      f.write(
        {
          flickr_url: flickr_url,
          photo_url: size['source'],
          author: image['metadata']['author'],
          face_rect: image['in_the_wild']['face_rect']
        }.to_json
      )
    end
    written_idx += 1
  rescue
    # pass
  end
end
