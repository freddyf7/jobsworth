# encoding: UTF-8
module TodosHelper

  def delete_todo_link(todo)
    image = image_tag("cross_small.png", :class => "tooltip",
                      :title => _("Delete <b>%s</b>.", h(todo.name)).html_safe)
    link_to_function image, "deleteTodo(#{todo.id}, #{@task.id})"
  end

  def todo_open_close_check_box(todo)
    title = _('Open <b>%s</b>', h(todo.name))
    if todo.done?
      title = _("Close <b>%s</b>", h(todo.name))
    end

    url = "/todos/toggle_done/#{ todo.id }?task_id=#{ @task.id }"
    id = todo.id

    check_box("todo", "done", { :title => title,
                :checked => todo.done?,
                :class => "button tooltip checkbox",
                :id => "button_#{ id }",
                :onclick => "toogleDone(this);"
              })
  end

  def new_todo_open_close_check_box(todo)
    title = _('Open <b>%s</b>', h(todo.name))
    if todo.done?
      title = _("Close <b>%s</b>", h(todo.name))
    end

    check_box("todo", "done", { :title => title,
                :checked => todo.done?,
                :class => "button tooltip checkbox",
                :onclick => "todoOpenCloseCheckForUncreatedTask(jQuery(this).attr('checked'), this)"
              })
  end

  def add_new_todo
    link_to_function(_("New To-do Item")) do |page|
      todo = Todo.new(:creator_id => current_user.id)
      page << "jQuery('#todos-clone').append('#{escape_javascript render_to_string(:partial => "/todos/new_todo", :locals => { :todo => todo})}')"
      page << "addNewTodoKeyListenerForUncreatedTask(this, 'new');new_task_form();"
    end
  end

end
