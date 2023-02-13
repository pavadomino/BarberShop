require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pony'
require 'sqlite3'

def get_db
  db = SQLite3::Database.new 'barbershop.db'
  db.results_as_hash = true
  return db
end

def read_mail_creds
  data = {}
  file = File.open('/Users/paveldomino/.creds_scripts/.mail', 'r')
  file.readlines.each do |line|
    var, val = line.chomp.split(':')
    data[var] = val
  end
  file.close
  user = data['user']
  password = data['password']
  return user, password
end

def is_barber_exists? db, name
  db.execute('select * from Barbers where name = ?', [name]).length > 0
end

def seed_db db, barbers
  barbers.each do |barber|
    if !is_barber_exists? db, barber
      db.execute('insert into Barbers (name) values (?)', [barber])
    end
  end
end

before do
  db = get_db
  @list_barbers = db.execute('select name from Barbers;')
  db.close
end

configure do
  db = get_db
  db.execute 'CREATE TABLE IF NOT EXISTS
    "Users"
    (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "username" VARCHAR,
      "phone" VARCHAR,
      "barber" VARCHAR,
      "datestamp" VARCHAR,
      "color" VARCHAR
    );'
  db.execute 'CREATE TABLE IF NOT EXISTS
    "Contacts"
    (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "mailbox" VARCHAR,
      "message" TEXT
    );'
  db.execute 'CREATE TABLE IF NOT EXISTS
    "Barbers"
    (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "name" TEXT NOT NULL UNIQUE
    );'

  barbers = ['Walter White', 'Jessie Pinkman', 'Gus Fring', 'Roman Pushkin', 'Mike Ermantraut']
  seed_db db, barbers
  db.close
end

get '/' do
	erb "Hello! <a href=\"https://github.com/bootstrap-ruby/sinatra-bootstrap\">Original</a> pattern has been modified for <a href=\"http://rubyschool.us/\">Ruby School</a>"
end

get '/about' do
   @error = 'Something wrong!'
	erb :about
end

get '/visit' do
  erb :visit
end

post '/visit' do
  @username = params[:username]
  @phone = params[:phone]
  @datetime = params[:datetime]
  @barber = params[:barber]
  @color = params[:color]

  hh = { :username => 'Введите имя',
         :phone => 'Введите номер телефона',
         :datetime => 'Введтие дату и время'}

  @error = hh.select { |key,_| params[key] == ''}.values.join(", ")

  if @error != ''
    return erb :visit
  end

  db = get_db
  db.execute 'INSERT INTO
    Users
    (
      username,
      phone,
      barber,
      datestamp,
      color
    )
    VALUES
    (
      ?,?,?,?,?
    )', [@username, @phone, @barber, @datetime, @color]
  db.close

  erb "#{@username} Вы были успешно записаны!"
end

get '/contacts' do
  erb :contacts
end

post '/contacts' do
  @email = params[:email]
  @comments = params[:comments]

  db = get_db
  db.execute 'INSERT INTO
    Contacts
    (
      mailbox,
      message
    )
    VALUES
    (?,?)', [@email, @comments]
  db.close

  user, password = read_mail_creds

  Pony.mail({
    :from => user,
    :to => user,
    :via => :smtp,
    :subject => "Message from #{@email}",
    :body => "Please check comments from the client:\n#{@comments}",
    :attachments => {"contacts.txt" => File.read("./public/contacts.txt")},
    :via_options => {
      :address              => 'smtp.gmail.com',
      :port                 => '587',
      :enable_starttls_auto => true,
      :user_name            => user,
      :password             => password,
      :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
      :domain               => "gmail.com" # the HELO domain provided by the client to the server
    }
  })

  erb 'Ваш запрос был отправлен!'
end

get '/showusers' do
  string = ''
  db = get_db
  @results = db.execute 'SELECT * FROM Users ORDER BY id DESC;'
  db.close

  erb :showusers
end
