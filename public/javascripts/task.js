// -------------------------
//  Task edit
// -------------------------

/* Load a task into the edit panel by ajax */
function loadTask(id) {
	jQuery("#task").fadeOut();
	jQuery.get("/tasks/edit/" + id + "?format=js", {}, function(data) {
		jQuery("#task").html(data);
		jQuery("#task").fadeIn('slow');
		init_task_form();
  });
}

function loadBacklogTask(id) {
	jQuery("#task").fadeOut();
	jQuery.get("/tasks/edit/" + id + "?format=js&redireccion=edit", {}, function(data) {
		jQuery("#task").html(data);
		jQuery("#task").fadeIn('slow');
		init_task_form();
  });
}

// refresh the milestones select menu for all milestones from project pid, setting the selected milestone to mid
// also old /milestones/get_milestones returns line of javascript code `jQuery('#add_milestone').[show()|hide]`
// new /milestones/get_milestones returns flag add_milestone_visible
function refreshMilestones(pid, mid) {
  jQuery.getJSON("/milestones/get_milestones", {project_id: pid},
    function(data) {
      select=jQuery('#task_milestone_id');
      select.empty();
        options= data.options;
      for( var i=0; i<options.length; i++ ) {
        select.append(jQuery("<option data-date=\"" + options[i].date + "\" value= \"" + options[i].value +"\" >"+ options[i].text+ "</option>"));
      }
      jQuery("#task_milestone_id value['"+ mid + "']").attr('selected','selected');
      if (data.add_milestone_visible){
        jQuery('#add_milestone').show();
      } else{
        jQuery('#add_milestone').hide();
      }
  });
}



/* TASK OWNER METHODS */
function removeTaskUser(sender) {
    sender = jQuery(sender);
    sender.parent(".watcher").remove();
    highlightWatchers();
}

function removeCustomerResponse(sender){
    sender = jQuery(sender);
    sender.parent().remove();
    jQuery('#task_wait_for_customer').attr('checked', false);
    jQuery('#snooze_until').hide();
}

function toggleTaskIcon(sender) {
    var div = jQuery(sender).parents(".watcher");

    var input = div.find("input.assigned");
    var icon = div.find(".icon.assigned");

    if (input.attr("disabled")) {
        div.addClass("is_assigned");
        input.attr("disabled", false);
    }
    else {
        input.attr("disabled", true);
        div.removeClass("is_assigned");
    }
}

/*
  Adds the selected user to the current tasks list of users
*/
function addUserToTask(event, ui) {
    var userId = ui.item.id;
    var taskId = jQuery("#task_id").val();
    var url = tasks_path('add_notification');
    var params = {user_id : userId, id : taskId};
    addUser(url, params);
    jQuery(this).val("");
    return false;

}

/*
 Shows the stats for the selected developer
*/
function showDevStats(event, ui){
    var url = "/sprint_planning/add_velocity_actual_project";
    id_proyecto = jQuery('#milestone_project_id_2 option:selected').val();
    id_developer = ui.item.id;
    alert(id_proyecto+'dev:'+id_developer);
    var params = {project_id : id_proyecto,developer_id : id_developer};

    jQuery.get(url, params, function(data) {
        jQuery("#speed_actual").val(data);
    });
}

/*
  Adds any users setup as auto add to the current task.
*/
function addAutoAddUsersToTask(clientId, taskId, projectId) {
    var url = tasks_path("add_users_for_client");
    var params = {client_id : clientId, id : taskId, project_id : projectId};
    addUser(url, params);
}

function addVelocityToTask(milestoneId) {
    var url = tasks_path("add_velocity_for_client");
    var params = {milesonte_id : milestoneId};
    addVelocity(url, params);
    addVelocityDesviation("velocity_deviation_for_client", params)
}

function addPointsPerHourToTask(milestoneId) {
    var url = tasks_path("present_points_per_hour_to_client");
    var params = {milesonte_id : milestoneId};
     jQuery.get(url, params, function(data) {
        jQuery("#extra_points_per_hour").val(data);
    });
}


function addTotalEstimatePointsCalc() {
    var velocity = jQuery("#task_points_team_velocity").val();
    var expert = jQuery("#task_points_expert_judgment").val();
    var pp = jQuery("#task_points_planning_poker").val();
    var project = jQuery("#task_project_id option:selected").val();
    var url = tasks_path("calculate_total_estimate_points_for_client");
    var params = {vel_points: velocity, expert_points: expert ,pp_points: pp ,project_id: project};
    jQuery.get(url, params, function(data) {
        jQuery("#task_total_points").val(data);
    });
}

function addDurationToTask() {
    var points = jQuery("#task_total_points").val();
    var milestoneId = jQuery('#task_milestone_id option:selected').val();
    var points_h = jQuery("#extra_points_per_hour").val();
    var url = tasks_path("calculate_duration_base_points_for_client");
    var params = {points: points, milesonte_id : milestoneId, points_h: points_h};
    addDuration(url,params)
}


function addDuration(url,params) {
    jQuery.get(url, params, function(data) {
        jQuery("#task_duration").val(data);
    });
}


function addVelocity(url, params){
    jQuery.get(url, params, function(data) {
        jQuery("#task_points_team_velocity").val(data);
    });
}

function addVelocityDesviation(url, params){
    jQuery.get(url, params, function(data) {
        jQuery("#task_points_team_velocity_desviation").html("Standard Desviation: " + data);
    });
}

function addUser(url, params){
    jQuery.get(url, params, function(data) {
        jQuery("#task_notify").append(data);
        highlightWatchers();
    });
}
/*
  Adds the selected customer to the current task list of clients
*/
function addCustomerToTask(event, ui) {
    var clientId = ui.item.id;
    var taskId = jQuery("#task_id").val();

    var url = tasks_path("add_client");
    var params = {client_id : clientId, id : taskId};
    jQuery.get(url, params, function(data) {
                jQuery("#task_customers").append(data);
    });

    addAutoAddUsersToTask(clientId, taskId);
    jQuery(this).val("");
    return false;
}
/*
  If this task has no linked clients yet, link the one that
  project belongs to and update the display.
*/
function addClientLinkForTask(projectId) {
    var customers = jQuery("#task_customers").text();

    if (jQuery.trim(customers) == "") {
        var url = tasks_path("add_client_for_project");
        var params = {project_id : projectId};
        jQuery.get(url, params, function(data) {
            jQuery("#task_customers").html(data);
        });
    }
}

/*
Toggles the todo display or edit fields
*/
function toggleTodoEdit(sender) {
    var todo = jQuery(sender).parents(".todo");
    var display = todo.find(".display");
    var edit = todo.find(".edit");
    display.toggle();
    edit.toggle();
}
/*
Adds listeners to handle users pressing enter in the todo
edit field
*/
function addTodoKeyListener(todoId, taskId) {
  var todo = jQuery("#todos-" + todoId);
  var input = todo.find(".edit input");

  input.keypress(function(key) {
    if (key.keyCode == 13) {
      jQuery(".todo-container").load("/todos/update/" + todoId,  {
        "_method": "PUT",
        task_id: taskId,
        "todo[name]": input.val()
      });

      key.stopPropagation();
      return false;
    }
  });
  initSortableForTodos();
}

/*
Adds listeners to handle users pressing enter in the todo
create field
*/
function addNewTodoKeyListener(taskId) {
  var todo = jQuery("#new-todos");
  var input = todo.find(".edit input");

  input.keypress(function(key) {
    if (key.keyCode == 13) {
      jQuery.ajax({
        url: '/todos/create?task_id='+ taskId + '&todo[name]=' + input.val(),
        type: 'POST',
        dataType: 'json',
        success:function(response) {
          jQuery('.todo-container').html(response.todos_html);
          jQuery('#todo-status-' + response.task_dom_id).html(response.todos_status);
          initSortableForTodos();
        },
        beforeSend:function() {showProgress();},
        complete:function() {hideProgress();}
      });
      key.stopPropagation();
      return false;
    }
  });
}

/*
 Add function to handle open/close task
 For New Task
*/

function todoOpenCloseCheckForUncreatedTask(done, sender) {
  if (jQuery(sender).siblings(".edit").is(':visible')){
    var todoName = jQuery(sender).siblings(".edit").children('input').val();
  } else {
    var todoName = jQuery(sender).siblings(".display").text();
  }
  jQuery.ajax({
    url: '/todos/toggle_done_for_uncreated_task/' + done + '?name=' + todoName,
    dataType: 'html',
    success:function(response) {
      jQuery(sender).parent().replaceWith(response);
    },
    beforeSend: function(){showProgress();},
    complete: function(){hideProgress();},
    error:function (xhr, thrownError) {
      alert("Invalid request");
    }
  });
}

/*
  Add function to handle new todo
  For new Task
*/


function new_task_form() {
    var todo = jQuery("#todos-clone").children("li:last-child");
    var display = todo.find(".display");
    var edit = todo.find(".edit");

    display.toggle();
    edit.toggle();
}

function addNewTodoKeyListenerForUncreatedTask(sender, button) {
     if (button == "edit") {
       var li_element = jQuery(sender).parent().parent();
       var input = jQuery(sender).parent().siblings(".edit").children("input");
     } else if (button == "new") {
       var li_element = jQuery("#todos-clone").children("li:last-child");
       var input = li_element.children("span.edit").children("input");
     }

    input.keypress(function(key) {
        if (key.keyCode == 13) {
            li_element.children(".display").show();
            li_element.children(".display").text(input.val());
            li_element.children(".edit").children("input").val(input.val());
            li_element.children(".edit").hide();

            key.stopPropagation();
            return false;
        }
    });
}

function init_task_form() {
    jQuery('#comment').focus();

    jQuery('#work_log_duration').click(function(){
        jQuery('#worklog_extra').show();
    });

    attach_behaviour_to_project_select();
    attach_behaviour_to_milestone_select();
    jQuery("div.log_history").tabs();
    jQuery('.autogrow').autogrow();
    jQuery('#comment').keyup(function() {
        highlightWatchers();
    });
    jQuery(function() {
        jQuery('#search_filter').catcomplete({
              source: '/task_filters/search',
              select: addSearchFilter,
              delay: 800,
              minLength: 3
        });
    });
    autocomplete('#task_customer_name_auto_complete', '/tasks/auto_complete_for_customer_name', addCustomerToTask);
    autocomplete('#dependencies_input', '/tasks/auto_complete_for_dependency_targets', addDependencyToTask);
    autocomplete('#resource_name_auto_complete', '/tasks/auto_complete_for_resource_name/customer_id='+ jQuery('#resource_name_auto_complete').attr('data-customer-id'), addResourceToTask);
    autocomplete('#user_name_auto_complete', '/tasks/auto_complete_for_user_name', addUserToTask);
    autocomplete('#user_name_auto_complete', '/tasks/auto_complete_for_user_name', showDevStats);
    autocomplete_multiple_remote('#task_set_tags', '/tags/auto_complete_for_tags' );

    initSortableForTodos();

    jQuery('#snippet').click(function() {
      jQuery(this).children('ul').slideToggle();
    });

    jQuery('#snippet ul li').hover(function() {
      jQuery(this).toggleClass('ui-state-hover');
    });

    jQuery('#snippet ul li').click(function() {
      var id = jQuery(this).attr('id');
      id = id.split('-')[1];
      jQuery.ajax({url: '/pages/snippet/'+id, type:'GET', success: function(data) {
        jQuery('#comment').val(jQuery('#comment').val() + '\n' + data);
      }});
    });

    jQuery('#add_milestone img').click(add_milestone_popup);
    jQuery('#task_project_id').change(function() {
      jQuery("#milestone_project_id").val(jQuery('#task_project_id').val());
      appendPopup("/milestones/quick_new?project_id=" + jQuery("#task_project_id").val(), "body", false);
    });

    jQuery('div.file_thumbnail a').slimbox();
    jQuery(".datefield").datepicker({constrainInput: false, dateFormat: userDateFormat});
    updateTooltips();
    jQuery('div#target_date a#override_target_date').click(function(){
        jQuery('div#target_date').hide();
        jQuery('div#due_date_field').show();
        return false;
    });

    jQuery('div#target_date a#clear_target_date').click(function(){
        jQuery('div#target_date span').html(jQuery('#task_milestone_id :selected').attr('data-date'));
        jQuery('div#due_date_field input').val("");
        jQuery(this).hide();
        jQuery('div#target_date a#override_target_date').show();
        return false;
    });

    jQuery('div#due_date_field input').blur(set_target_date);

    jQuery('div#due_date_field input').datepicker({
        constrainInput: false,
        dateFormat: userDateFormat,
        onSelect: set_target_date
    });
    jQuery('#task_milestone_id').change(function(){
      if(jQuery('div#due_date_field input').val().length == 0){
        jQuery('div#target_date span').html(jQuery('#task_milestone_id :selected').attr('data-date'));
      }
    });

    jQuery('#user_access_public_privat').click(toggleAccess);
    bind_task_hide_until_callbacks();
    jQuery('#users_to_notify_popup_button').live("click", showUsersToNotifyPopup);
    jQuery(function(){
      collapsiblePanel('started_at');
    });
}

function set_target_date(){
        jQuery('div#target_date').show();
        jQuery('div#due_date_field').hide();
        if(jQuery('div#due_date_field input').val().length == 0){
          jQuery('div#target_date span').html(jQuery('#task_milestone_id :selected').attr('data-date'));
        } else {
            jQuery('div#target_date span').html(jQuery('div#due_date_field input').val());
            jQuery('div#target_date a#override_target_date').hide();
            jQuery('div#target_date a#clear_target_date').show();
        }
}

function delete_todo_callback() {
  jQuery(".delete_todo").bind("ajax:success", function(data, status, xhr) {
    jQuery(this).parent().remove();
  });
}
// this variable is used to cache the last state so we don't run
// all of highlightWatchers() on every keystroke
var task_comment_empty = null;

function remove_file_attachment(file_id, message) {
  var answer = confirm(message);
  if (answer){
    jQuery.ajax({
      url: '/project_files/destroy_file/'+ file_id,
      dataType: 'json',
      success:function(response) {
        if (response.status == 'success') {
           var div=jQuery('#projectfiles-' + file_id);
           div.fadeOut('slow');
           div.html('<input type="hidden" name="delete_files[]" value="' + div.attr('id').split('-')[1] + '">');
        } else {
          flash_message(response.message);
        }
      },
      beforeSend: function(){showProgress();},
      complete: function(){hideProgress();},
      error:function (xhr, thrownError) {
        alert("Error : " + thrownError);
      }
    });
  }
}

function highlightWatchers() {
	var comment_val = jQuery('#comment').val();
	
  if (comment_val !== task_comment_empty) {
	  if (comment_val == '') {
	    jQuery('.watcher').removeClass('will_notify');
	    jQuery('#notify_users').html('');
	  } else {
	    if (jQuery('#accessLevel_container div').hasClass('private')) {
	      jQuery('.watcher').removeClass('will_notify');
	      jQuery('.watcher.access_level_2').addClass('will_notify');
	    } else {
	      jQuery('.watcher').addClass('will_notify');
	    }
	    var watcher = "Notify: ";
	    jQuery('div.watcher.will_notify a.username span').each(function() {
	      watcher = watcher + jQuery(this).html() + ", ";
	    });
	    jQuery('#notify_users').html(watcher.substring(0,watcher.length-2));
	  }
	  task_comment_empty = (comment_val == '');
  }
}

function add_milestone_popup() {
  if (jQuery("#task_project_id").val() == "") {
    alert("Please select project before adding Iteration !!");
  } else {
    jQuery("#milestone_name").val(" ");
    jQuery("#milestone_due_at").val(" ");
    jQuery("#milestone_init_date").val(" ");
    jQuery("#milestone_user_id").val(" ");
    jQuery("#milestone_description").val(" ");
    var popup = jQuery("span#ui_popup_dialog").dialog({
        autoOpen: false,
	    title: 'New Iteration',
        width: 370,
        draggable: true
	});
	popup.dialog('open');
        jQuery('#add_milestone_form').submit(function(){
          jQuery('#errorExplanation').remove();
          if (jQuery("#milestone_name").val() == 0){
            jQuery('<div></div>').attr({'id': 'errorExplanation', 'class': 'errorExplanation'})
            .append('Name can not be blank').insertBefore('#add_milestone_form');
            return false;
          }
        });
        // refresh milestone and destroy dialog after a successful milestone addition
        jQuery('#add_milestone_form').bind("ajax:success", function(event, json, xhr) {
             authorize_ajax_form_callback(jQuery.parseJSON(json));
             var project_id = jQuery.parseJSON(json).project_id;
             var milestone_id = jQuery.parseJSON(json).milestone_id;
             parent.refreshMilestones(project_id, milestone_id);
             jQuery('span#ui_popup_dialog').dialog('destroy');
        });
	return false;
  }
}

function toogleDone(sender) {
  var todoId = jQuery(sender).parent().attr("id").split("-")[1];
  var taskId = jQuery("#task_id").val();
  jQuery.ajax({
    url: '/todos/' + todoId + '/toggle_done/' + '?task_id=' + taskId + '&format=json',
    dataType: 'json',
    success:function(response) {
      jQuery('.todo-container').html(response.todos_html);
      jQuery('#todo-status-' + response.task_dom_id).html(response.todos_status);
    },
    beforeSend:function() {showProgress();},
    complete:function() {hideProgress();}
  });
}

function deleteTodo(todoId, taskId) {
  jQuery.ajax({
    url: '/todos/' + todoId + '?task_id=' + taskId,
    dataType: 'json',
    type: 'delete',
    success:function(response) {
      jQuery('#todo-status-' + response.task_dom_id).html(response.todos_status);
      jQuery('#todos-' + todoId).remove();
    },
    beforeSend:function() {showProgress();},
    complete:function() {hideProgress();}
  });
}

function initSortableForTodos() {
  jQuery('.task-todo').sortable({update: function(event,ui){
    var todos= new Array();
    jQuery.each(jQuery('.task-todo li'),
      function(index, element){
        var position = jQuery('input#todo_position', element);
        position.val(index+1);
        todos[index]= {id: jQuery('input#todo_id', element).val(), position: index+1} ;
      });
      jQuery.ajax({url: '/todos/reorder', data: {task_id: jQuery('input#task_id').val(), todos: todos}, type: 'POST'});
    }
  });
}

function bind_task_hide_until_callbacks(){
    jQuery('#task_hide_until').change(function(){
      jQuery('#snooze_until_date span').html(jQuery(this).val());
      if(jQuery(this).val().length>0) {
         jQuery('#snooze_until_date').show();
      }
    }).datepicker({dateFormat: userDateFormat}); 

    jQuery('#snooze_until_datepicker').click(function(){
        jQuery('#task_hide_until').datepicker('show');
        return false;
    });
    jQuery('#remove_snooze_until_date').click(function(){
        jQuery('#snooze_until_date').hide();
        jQuery('#task_hide_until').val('');
        return false;
    });
}

function showUsersToNotifyPopup() {

  if(jQuery('#users_to_notify_list ul').is(':visible')) { 
    jQuery('#users_to_notify_list ul').slideUp(); 
    return false;
  }

  var watcherIds = jQuery(".watcher_id").map(function () {
    return jQuery(this).val();
  }).get().join(",");

  var taskId = jQuery("#task_id").val();

  jQuery('#users_to_notify_list').
    load("/tasks/users_to_notify_popup?id=" + taskId + "&watcher_ids=" + watcherIds, 
      function() {

        jQuery('#users_to_notify_list ul').slideDown(400, function() {
          jQuery('#users_to_notify_list ul').focus();

          jQuery('#users_to_notify_list ul').bind('focusout', function() {
            jQuery('#users_to_notify_list ul').slideUp(800);
          });
        });

        jQuery('#users_to_notify_list ul li').hover(function() {
          jQuery(this).toggleClass('ui-state-hover');
        });

        jQuery('#users_to_notify_list ul li a').bind('click', function(){
          jQuery('#users_to_notify_list ul').slideUp();
          var userId = jQuery(this).attr("id").split("_")[1];
          var url    = tasks_path('add_notification');
          var params = {user_id : userId, id : taskId};
          addUser(url, params);
          return false;
        });
      });

  return false;
}

function nextTasks_makeSortable() {

}

jQuery(document).ready(function() {
  jQuery("#nextTasks ul").sortable({
		stop: function(event, ui) {
			var moved = ui.item.children("a").data("taskid");
			var prev = ui.item.prev("li").children("a").data("taskid");
			jQuery.post("/tasks/change_task_weight", {"prev": prev, "moved": moved});
		}
	});

	jQuery("#nextTasks_more a").click(function(){
	  var count = jQuery('#nextTasks ul li').length + 5;
	  jQuery('#nextTasks ul').load("/tasks/nextTasks?count=" + count + " ul li");
	  return false;
	});
});
