require 'rubygems'
require 'sinatra'
require 'mongo'
require 'bson'
require 'uri'

#is for output in the console using foreman start
$stdout.sync = true 

#Connects us to Database hosted as heroku addon on mongo hq look here: https://devcenter.heroku.com/articles/mongohq#use-with-ruby
dbConfig = URI.parse(ENV['MONGOHQ_URL'])
db_name = dbConfig.path.gsub(/^\//, '')
db = Mongo::Connection.new(dbConfig.host, dbConfig.port).db(db_name)
db.authenticate(dbConfig.user, dbConfig.password) unless (dbConfig.user.nil? || dbConfig.user.nil?)

get '/login' do
	%{<form method = "post" action ="login">
	<input name="nickname" type="text" placeholder="Nickname" required pattern="[A-Za-z\s]+"></input><br>
	<input name="password" type="password" placeholder="Password" required pattern="[0-9]+"></input><br>
	<button>Login!</button>
	</form>
	<br><a href='welcome'>Back</a>}

end

post '/login' do
	nickname = params[:nickname]
    password = params[:password]
    puts nickname
    puts password
	user = db['users'].find({ '$and' => [{:nickname => nickname}, {:password => password}]} ).to_a
	puts user
	if 
		user.size > 0
		"User found"
	else
		user.size <= 0
		"User not found"
	end
	
end

get '/signup' do
	%{<form method = "post" action ="signup">
	<input name="nickname" type="text" placeholder="Nickname" required pattern="[A-Za-z\s]+"></input><br>
	<input name="password" type="password" placeholder="Password" required pattern="[0-9]+"></input><br>
	<button>Sign up!</button>
	</form>
	<br><a href='welcome'>Back</a>}
end

post '/signup' do
	nickname = params[:nickname]
    password = params[:password]
    #favorite = params[:favorite]
	puts nickname
	puts password
	#puts favorite
   	user = db['users'].insert({:nickname => nickname, :password => password})
   	puts user
   	"Successfully signed up! <a href='login'>Login</a> <a href='welcome'>Back</a>"


end

get '/welcome' do
	'<center><h1>Welcome to your phonebook!</h1>
	<a href="login">Login</a>
	<a href="signup">Signup</a></center>'
end

#List all users in collection 'namen' + delete & update link 
get '/' do
	#reads collection 'namen' & transforms into array
	telefonbuch = db['namen'].find.sort(:nachname => :asc).to_a
	#result = apply block to every element in telefonbuch & join elements with break in between
	result = telefonbuch.map{|document| "<a href='delete?id=#{document['_id']}'>Delete</a>||<a href='update?id=#{document['_id']}'>Update</a>||#{document['nachname']}, #{document['vorname']}, #{document['nummer']} "}.join("<br>")
	#Adds link to get '/new'
	result = result + '<br><br><a href="new">New Entry</a>' + '<br><br><form method = "post" action ="search">
	<input name="tosearch" type="text" placeholder="Search"></input>
	<button>Go search!</button>
	</form>'
	#returns the result
	result
end

#searches for search term
post '/search' do
#get input from search in get '/'
	search = params[:tosearch]
	#debugging
	puts "Input was = #{search}"
	#search for search entry in our database
	entries = db['namen'].find({'$or' => [{:vorname => /#{Regexp.escape(search)}/ix}, {:nachname => /#{Regexp.escape(search)}/ix}, {:nummer => /#{Regexp.escape(search)}/ix}]}).to_a 
	#converts number of entries into number
	entrysize = entries.size

	#x is set to zegit ro cause so the while loop starts circling at zero
	x = 0
	#setting empty string found
	found = " "
	#while x is smaller than entrysize continue loop and concate found
		while x < entrysize do
			
			#if there is an entry concate it into found
			if entry = entries.shift
				#convert each value into a variable for a string
				vorname = entry["vorname"]
				nachname = entry["nachname"]
				nummer = entry["nummer"]
				#add 1 to x per cycle so it stops when the number of entries is reached
				x += 1
				#adds entry as string to found
				found += "___________________<br><br>Name: #{vorname} #{nachname}<br><br>Number: #{nummer}<br><br><br>"
				#debugging
				puts found

			else
				#if there are no entries display this message
				"Sorry, no entries found!"
			end
		
		end
#What´s gonna be on the search result screen
"Number of entries found: #{entrysize}<br><br>#{found}<a href='/'>Back</a>"

end

#Opens form to fill in names 
get '/new' do
	#renders our form in html and sends it to post '/new'
	'<form method="post" action="new">
		<input name="vorname" type="text" placeholder="First name" required pattern="[A-Za-z\s]+"></input><br>
		<input name="nachname" type="text" placeholder="Last name" required pattern="[A-Za-z\s]+"></input><br>
		<input name="nummer"  type="text" placeholder="Phone number" pattern="[0-9]+" required></input>
		<button>Save</button>
	</form>'
end

#Adds new user to database and confirms it
post '/new' do
#set variables for data from form
     vorname = params[:vorname]
     nachname = params[:nachname]
     nummer = params[:nummer]
     #check if fields are filled in
	     if 
		    ((vorname != "") && (nachname != "")) && (vorname.match(/[^0-9\s]/) && nachname.match(/[^0-9\s]/)) && (nummer != "") && (nummer.match(/[^A-Za-z]/))
		     #for debugging in console
		     puts "#{params}"
		     #feed collection namen inside database with the values passed from get '/new' via params
		     db['namen'].insert({:vorname=> vorname.downcase.split(" ").map(&:capitalize).join(" "), :nachname=> nachname.downcase.split(" ").map(&:capitalize).join(" "), :nummer => nummer})
		     "#{nachname}, #{vorname},#{nummer} have been added! <a href='new' >New Entry</a> <a href='/'>All</a> "
	 	elsif 
	 		#if a field is not filled
	 		((vorname != "") && (nachname != "") && (nummer != "")) != true
	 		"Please fill in all required fields! <a href='new'>New Entry</a>"
	 	else
	 		#if there are no numbers in the number field
	 		nummer.match(/[0-9]+/) != true
	 		"Wrong format! Please enter digits for a Phone number and letters for your name! <a href='new'>New Entry</a>"
	 	end
end

#Delete a user from database
get '/delete' do
    #gets id to delete from get '/delete?id=#{document['_id']}'
    id = params[:id]
    vorname = params[:vorname]
     nachname = params[:nachname]
    #removes entry with that id from database
	db['namen'].remove({:_id=> BSON::ObjectId.from_string(id)})
	#confirms removal and provides links to get '/new' and get '/'
     "Entry was removed! <a href='new'>New Entry</a> <a href='/'>All</a> "
end

#Give 'new' form with current user
get '/update' do
	#gets ID to update from get 'update?id=#{document['_id']}''
	id = params[:id]
	#find ID in database and convert to array
	persons = db['namen'].find({:_id=> BSON::ObjectId.from_string(id)}).to_a
	#convert array database object to hash entry
	person = persons[0]
	#debugging on console
	puts "#{persons}"
	puts "#{person}"
	#set vorname, nachname equal to person hash entries
	vorname = person["vorname"]
	nachname = person["nachname"]
	nummer = person["nummer"]
	#debugging
	puts "#{vorname}"
	puts "#{nachname}"
	#form that contains current names and sends ID to post '/update'
	 %{<form method="post" action="update?id=#{id}">
		<input name="vorname" type="text" placeholder="First name" value="#{vorname}" required pattern="[A-Za-z\s]+"></input><br>
		<input name="nachname" type="text" placeholder="Last name" value="#{nachname}" required pattern="[A-Za-z\s]+""></input><br>
		<input name="nummer" type="text" placeholder="Phone number" value="#{nummer}" required pattern="[0-9]+"></input><br>
		<button>Save</button>
	</form>}

end

#updates database with new entry
post '/update' do
	#debugging
	print params
	#gets ID to update from get 'update?id=#{id}'
	id = params[:id]
	#gets new names from form
	vorname = params[:vorname]
	nachname = params[:nachname]
	nummer = params[:nummer]
	     
	     #check if fields are filled in
	     if 
		    ((vorname != "") && (nachname != "")) && (vorname.match(/[A-Za-z\s]+/) && nachname.match(/[A-Za-z\s]+/)) && (nummer != "") && (nummer.match(/[0-9]+/))
		     #find correlating database entry and convert to hash object
			persons = db['namen'].find({:_id=> BSON::ObjectId.from_string(id)}).to_a
			person = persons[0]
			#fill hash with new names from form
			person["vorname"] = vorname.downcase.split(" ").map(&:capitalize).join(" ")
			person["nachname"] = nachname.downcase.split(" ").map(&:capitalize).join(" ")
			person["nummer"] = nummer.downcase.split(" ").map(&:capitalize).join(" ")
			#save new entries from person hash to database
			db['namen'].save(person)
			#updated message
		     "#{nachname}, #{vorname},#{nummer} has been updated! <a href='new'>New</a> <a href='/'>All</a> "
	 	elsif 
	 		((vorname != "") && (nachname != "") && (nummer != "")) != true
	 		"Please fill in all required fields! <a href='new'>New Entry</a>"
	 	else
	 		nummer.match(/[0-9]+/) != true
		"Wrong format! Please enter digits for a Phone number and letters for your name! <a href='new'>New Entry</a>"	 	
		end


end




