require 'sinatra'
require 'yaml'
require 'rack/utils'


# Load all collections from the YAML file
def load_collections
  unless File.exist?('collections.yml')
    FileUtils.cp('collections.yml.example', 'collections.yml')
  end
  YAML.load_file('collections.yml').sort_by{|collection| collection['ZY'] }
end

def save_collections(collections)
  File.open('collections.yml', 'w') { |f| f.write(collections.to_yaml(line_width: -1)) }
end

# Load all screen files from the 'screens' directory
def load_screens
  Dir.glob('screens/*.erb').map do |file_path|
    { name: File.basename(file_path), content: File.read(file_path) }
  end
end

# Route for landing page showing all screen files
get '/' do
  @screens = load_screens
  collections = load_collections
  collection_conditions = collections.map do |collection|
    "(ZY = '#{collection['ZY']}' || $datasource = '#{collection['datasource']}')"
  end
  @collections = collection_conditions.join(' || ')
  erb :index
end

get '/api' do
  @collections = load_collections
  xml_template = File.read('views/api_template.erb')
  @xml_content = ERB.new(xml_template).result(binding) # Render template content
  erb :api_view
end

# Route for editing collections
get '/edit_collections' do
  @collections = load_collections
  erb :edit_collections
end

# Route to update collections (through POST form submission)
post '/update_collections' do
  # Clean up and parse the collections data
  updated_collections = params['collections'].map do |collection|
    {
      'ZY' => collection['ZY'].to_s,
      'datasource' => collection['datasource'].to_s,
      'isTransfer' => collection['isTransfer'] == 'True'
    }
  end

  # Save the updated collections to YAML
  save_collections(updated_collections)

  redirect '/edit_collections'
end
