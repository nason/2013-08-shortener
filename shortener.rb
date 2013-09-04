require 'sinatra'
require "sinatra/reloader" if development?
require 'active_record'
require 'pry'

configure :development, :production do
    ActiveRecord::Base.establish_connection(
       :adapter => 'sqlite3',
       :database =>  'db/dev.sqlite3.db'
     )
end

# Handle potential connection pool timeout issues
after do
    ActiveRecord::Base.connection.close
end

# Quick and dirty form for testing application
#
# If building a real application you should probably
# use views: 
# http://www.sinatrarb.com/intro#Views%20/%20Templates
form = <<-eos
    <form id='myForm'>
        <input type='text' name="url">
        <input type="submit" value="Shorten"> 
    </form>
    <h2>Results:</h2>
    <h3 id="display"></h3>
    <script src="jquery.js"></script>

    <script type="text/javascript">
        $(function() {
            $('#myForm').submit(function() {
            $.post('/new', $("#myForm").serialize(), function(data){
                $('#display').html(data);
                });
            return false;
            });
    });
    </script>
eos

# Models to Access the database 
# through ActiveRecord.  Define 
# associations here if need be
#
# http://guides.rubyonrails.org/association_basics.html
class Link < ActiveRecord::Base
    def after_initialize params
        @url = @params[:url]
        @shortened = params.fetch('shortened')
    end

    def shortened
        @shortened
    end

end

get '/' do
    form
end

get '/l/:shortened' do
    $link = Link.find_by( shortened: @params[:shortened] )
    if $link.nil?
        status 404
    else
        redirect to( 'http://' + $link.url ), 303
    end
end

post '/new' do
    $link = Link.find_by( url: @params[:url] )
    if $link.nil?
        @params['shortened'] = @params[:url].hash.to_s(36)
        $link = Link.new @params
        $link.save
    end
    $link.shortened
    # binding.pry
end

get '/jquery.js' do
    send_file 'jquery.js'
end

####################################################
####  Implement Routes to make the specs pass ######
####################################################
