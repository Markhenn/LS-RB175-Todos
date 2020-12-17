require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

helpers do
  def completed?(list)
    "complete" if !count_todos(list).zero? && remaining_todos(list).zero?
  end

  def remaining_todos(list)
    list[:todos].count { |todo| !todo[:completed] } 
  end

  def count_todos(list)
    list[:todos].size
  end

  def sort_list(lists)
    list_index = {}

    lists.each_with_index do |list, index|
      list_index[list] = index
    end

    lists.sort_by { |list| completed?(list) ? 1 : 0 }.each do |list|
      yield(list, list_index[list])
    end
  end

  def sort_todos(todos)
    list_index = {}

    todos.each_with_index do |todo, index|
      list_index[todo] = index
    end

    todos.sort_by { |todo| todo[:completed] ? 1 : 0 }.each do |todo|
      yield(todo, list_index[todo])
    end
  end
end

get "/" do
  redirect "/lists"
end

# Show list of lists
get "/lists" do
  @lists = session[:lists]

  erb :lists
end

# Create a new list
get "/lists/new" do
  erb :new_list
end

# Return an error message if the list name is invalid
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? do |list|
    list[:name] == name && name != params[:list_name]
  end
    "The name for the list is already taken."
  end
end

# Return an error message if the todo name is invalid
def error_for_todo(name)
  if !(1..100).cover?(name.size)
    "Todo must be between 1 and 100 characters."
  end
end

# Add list to session
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Show a single to list
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  erb :list
end

# Edit a list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :edit_list
end

# Update an existing todolist
post "/lists/:id" do
  list_name = params[:list_name].strip
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{params[:id]}"
  end
end

# Delete a list
post "/lists/:id/delete" do
  id = params[:id]
  list = session[:lists].delete_at(id)
  session[:success] = "The list \"#{list[:name]}\" has been deleted."
  redirect "/lists"
end

# add todos to a list
post "/lists/:list_id/todos" do
  todo_name = params[:todo].strip
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  error = error_for_todo(todo_name)
  if error
    session[:error] = error
    erb :list
  else
    @list[:todos] << { name: todo_name, completed: false }
    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo
post "/lists/:list_id/todos/:id/delete" do
  todo_id = params[:id].to_i

  list_id = params[:list_id].to_i
  @list = session[:lists][list_id]
  @list[:todos].delete_at(todo_id)

  session[:success] = "The todo has been deleted"
  redirect "/lists/#{list_id}"
end

# Update status of a todo
post "/lists/:list_id/todos/:id" do
  list_id = params[:list_id].to_i
  @list = session[:lists][list_id]

  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "The todo has been updated"

  redirect "/lists/#{list_id}"
end

# Complete all todos
post "/lists/:list_id/complete_all" do
  list_id = params[:list_id].to_i
  @list = session[:lists][list_id]

  @list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = "All todos have been completed"
  redirect "/lists/#{list_id}"
end
