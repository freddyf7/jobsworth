// -------------------------
//  Task list grid
// -------------------------

// the column model which we want to cache on the browser
var columnModel;

/*
  Sends an ajax request to save the given user preference to the db
*/
function sprint_saveUserPreference(name, value) {
  var params = {"name": name, "value": value};
  jQuery.post("/users/set_preference",  params);
}

function sprint_getUserPreference(name) {
  var url = "/users/get_preference?name=" + name;
  jQuery.post("/users/set_preference",  params);
}

function sprint_selectRow(rowid) {
  jQuery('#sprint_backlog_list').setCell(rowid, 'read', 't');
  jQuery('#' + rowid).removeClass('unread');
  loadBacklogTask(rowid);
}

function sprint_setRowReadStatus(data) {
  for ( var i in data.tasks.rows ) {
    var row = data.tasks.rows[i];
    if (row.read == 'f') {
	    jQuery('#' + row.id).addClass('unread');
    }
  }
}

function sprint_taskListConfigSerialise() {
        var model = jQuery("#sprint_backlog_list").jqGrid('getGridParam', 'colModel');

        jQuery.ajax({
                type: "POST",
                url: '/users/set_backloglistcols',
                data: {model : JSON.stringify(model)},
                dataType: 'json',
                success: function(msg) {
                        alert( "Data Saved: " + msg );
                }
        });
}

var group_value = ""

function sprint_change_group() {
  var vl = jQuery("div.ui-pg-div > #sprint_chngroup").val();
  if(vl) {
    group_value = vl;
      jQuery.post("/users/set_task_grouping_preference/" +  vl, function() {
      if(vl == "clear") {
        jQuery("#sprint_backlog_list").jqGrid('groupingRemove',true);
      } else {
        jQuery("#sprint_backlog_list").jqGrid('groupingGroupBy',vl);
      }
    });
  }
}


/* Since the json call is asynchronous
  it is important that this function then calls
  the initGrid to finish loading the grid,
  but only after it has returned successfully
*/
jQuery(document).ready(function() {
  if (jQuery('#sprint_backlog_list').length) {
    jQuery.ajax({
      async: false,
      url: '/users/get_backloglistcols',
      dataType: 'json',
      success:function(response) {
        columnModel = response;
        sprint_initTaskList();
      },
      error:function (xhr, thrownError) {
        alert("Invalid task list model returned from server");
      }
    });
  }

  //override the standard reloadGrid event handler
  //save jggrid scroll position before call reloadGrid event
  var grid = jQuery("#sprint_backlog_list");
  var events = grid.data("events"); // read all events bound to
  var originalReloadGrid; // here we will save the original event handle
  // Verify that one reloadGrid event handler is set.
  if (events && events.reloadGrid && events.reloadGrid.length === 1) {
    originalReloadGrid = events.reloadGrid[0].handler; // save old event
    grid.unbind('reloadGrid');
    grid.bind('reloadGrid', function(e,opts) {
      savejqGridScrollPosition();
      originalReloadGrid(e,opts);
      restorejqGridScrollPosition();
    });
  }
});

function sprint_initTaskList() {
  var myGrid = jQuery('#sprint_backlog_list').jqGrid({
        url : '/sprint_planning/planning?format=json&userh=4',
        datatype: 'json',
        jsonReader: {
                root: "tasks.rows",
                userdata: "tasks.userdata",
                repeatitems:false
        },
        colModel : columnModel.colModel,
        loadonce: false,
        sortable : function(permutation) {sprint_taskListConfigSerialise();}, // re-order columns
        sortname: columnModel.currentSort.column,
        sortorder: columnModel.currentSort.order,
        postData: {
            milestone_id:
                function() {
                     iteration = jQuery("#milestone_id").val()
                     
                     if (iteration == null || jQuery("#milestone_id option:selected").text() == 'Select...'){
                         result = -1
                     }else{
                         result = iteration
                     }

                     return result

                },
            user_stories:
                function() {
                    var s                    
                    var result ='-'
                    s = jQuery("#backlog_list").jqGrid('getGridParam','selarrrow')
                    
                    for (i=0;i<s.length;i++){                        
                        result = result +'-'+s[i]
                    }
                    return result
                }
        },
        caption: "Sprint Backlog",
        viewrecords: true,
        multiselect: true,

        onSelectRow: function(rowid, status) {sprint_selectRow(rowid);},
        onClickGroup: function(hid, collapsed) {sprint_saveCollapsedStateToLocalStorage(hid, collapsed)},
        resizeStop: function(newwidth, index) {sprint_taskListConfigSerialise();},
        loadComplete: function(data) {sprint_restoreCollapsedState();
            jQuery("#load_sprint_backlog_list").hide();
            sprint_restorejqGridScrollPosition();
            sprint_setRowReadStatus(data);},
        shrinkToFit: true,

        pager: '#sprint_backlog_pager',
        emptyrecords: 'No user stories found.',
        pgbuttons:false,
        pginput:false,
        rowNum:200,
        recordtext: '{2} user stories found.',

        footerrow: true,
        userDataOnFooter: true,
        userdata: "userdata",

        height: 300,
        width: 720,

        grouping: jQuery("#sprint_chngroup").val() != "clear",
        groupingView: {
           groupField: [jQuery("#sprint_chngroup").val()],
           groupColumnShow: [false]
        }
  });



jQuery("#quitarSprint").click(function () {
   var seleccionadas
   seleccionadas = jQuery("#sprint_backlog_list").jqGrid('getGridParam','selarrrow')
  

   
   for (  var i = seleccionadas.length-1; i>=0; i--) {
    jQuery("#backlog_list").setSelection(seleccionadas[i].toString(),false);
    jQuery('#sprint_backlog_list').delRowData(seleccionadas[i]);
   }

//   alert(seleccionadas_2)
//   for (  var i = seleccionadas_2.length-1; i>=0; i--) {
//    jQuery("#backlog_list").setSelection(seleccionadas_2[i].toString(),false);
//   }
//
//   for (i=0;i<seleccionadas.length;i++){
//    jQuery("#backlog_list").jqGrid('setSelection',seleccionadas[i]);
//   }
   
});


var myReload = function() {
    myGrid.trigger('reloadGrid');
};

var keyupHandler = function (e,refreshFunction,obj) {
    var keyCode = e.keyCode || e.which;
    if (keyCode === 33 /*page up*/|| keyCode === 34 /*page down*/||
        keyCode === 35 /*end*/|| keyCode === 36 /*home*/||
        keyCode === 38 /*up arrow*/|| keyCode === 40 /*down arrow*/) {

        if (typeof refreshFunction === "function") {
            refreshFunction(obj);
       }
    }
};

jQuery("#cargarSprint").click(myReload).keyup(function (e) {
    keyupHandler(e,myReload,this);
});

  jQuery('#sprint_backlog_list').navGrid('#sprint_backlog_pager', {refresh:true, search:false, add:false, edit:false, view:false, del:false},
        {}, // use default settings for edit
        {}, // use default settings for add
        {}, // use default settings for delete
        {}, // use default settings for search
        {} // use default settings for view
  );

  jQuery("#sprint_backlog_list").jqGrid('sortableRows', {
    update: function(event, ui) {
    if (jQuery("#sprint_chngroup").val() != "clear") {
                var id = ui.item.index();
                for (i=id;i>=0;i--) {
                        if (jQuery("tbody.ui-sortable > tr.ui-widget-content").eq(i-1).attr("id").match(/task_listghead/) != null) {
                var group_id = jQuery("tbody.ui-sortable > tr.ui-widget-content").eq(i-1).attr("id");
                        var group_text = jQuery("#" + group_id + " > td").text();
                var group_icon;
                if (group_text == "") {
                        group_icon = jQuery("#" + group_id + " > td > span > img").attr("src");
                }
                        break;
                        }
                }
                var group = sprint_getCurrentGroup();
                jQuery.post("/tasks/set_group/"+ ui.item.attr("id") +"?group=" +  group + "&value=" + group_text+ "&icon=" + group_icon);
        if (group_text != "") {
                jQuery('.ui-sortable > tr#'+ ui.item.attr("id") +' > td[aria-describedby=\"task_list_'+ group + '\"]').text(group_text);
                jQuery('.ui-sortable > tr#'+ ui.item.attr("id") +' > td[aria-describedby=\"task_list_'+ group + '\"]').attr('title', group_text);
        } else if(group_icon != undefined) {
                var image = jQuery("#" + group_id + " > td").html();
                jQuery('.ui-sortable > tr#'+ ui.item.attr("id") +' > td[aria-describedby=\"task_list_'+ group + '\"]').html(image);
                jQuery('.ui-sortable > tr#'+ ui.item.attr("id") +' > td[aria-describedby=\"task_list_'+ group + '\"] > span.ui-icon').remove();
        }
        }
    }
  });

  jQuery("#sprint_backlog_list").jqGrid('gridResize', {
        stop: function(event, ui) {
                sprint_resizeGrid(); // force width
    },
    minHeight: 150,
    maxHeight: 1000
  });

//boton para agregar columnas a la tabla
//  jQuery("#backlog_list").jqGrid('navButtonAdd','#backlog_pager', {
//    caption: "Columns",
//    title: "Show/hide columns",
//    onClickButton : function () {
//      jQuery("#backlog_list").jqGrid('columnChooser', {
//        done: function (id) { taskListConfigSerialise(); }
//      });
//    }
//  });

//  jQuery("#sprint_backlog_list").jqGrid('navButtonAdd','#sprint_backlog_pager', {
//        caption: "Export",
//        title: "Export data to CSV",
//        onClickButton : function () {
//      window.location.href="/tasks/get_csv";
//        }
//  });

  jQuery("#sprint_backlog_list").jqGrid('navButtonAdd','#sprint_backlog_pager', {
      caption: jQuery("#sprint_groupby").html(),
      buttonicon: "none",
      id: "jgrid_footer_changegroup"
  });
  jQuery('#sprint_backlog_pager_center').remove();
  sprint_resizeGrid();
}

function parseStories(){


}

jQuery.extend(jQuery.fn.fmatter , {
  tasktime : function(cellvalue, options, rowdata) {
    var val = timeTaskValue(cellvalue);
    return val;
  }
});

jQuery.extend(jQuery.fn.fmatter , {
  read : function(cellvalue, options, rowdata) {
		return "<span class='unread_icon'/>";
  }
});


jQuery(window).bind('resize', function() {
  sprint_resizeGrid();
});

function sprint_resizeGrid() {
  jQuery("#sprint_backlog_list").setGridWidth(720); //allow for sidebar and margins
}

// -------------------------
//  Calendar
// -------------------------


jQuery(document).ready(function() {

  jQuery('#calendar').fullCalendar({
    events: "/tasks/calendar",
      theme: true,
      height: 350,

      eventClick: function(calEvent, jsEvent, view) {
        loadTask(calEvent.id);
      },

      editable: true,
      disableResizing: true,
      eventDrop: function(event,dayDelta,minuteDelta,allDay,revertFunc) {
        // FIXME: needs ajax callback to update task date
      }

        });
});

function sprint_timeTaskValue(cellvalue) {
        if (cellvalue == 0) {
          return "";
        }
        return Math.round(cellvalue/6)/10 + "hr";
}

function sprint_tasksViewReload()
{
    jQuery("#task_list").trigger("reloadGrid");
    jQuery('#calendar').fullCalendar('refetchEvents');
    if (jQuery("#ganttChart").length) {
        refresh_gantt();
    };
}

function sprint_ajax_update_task_callback() {
  jQuery('#taskform').bind("ajax:success", function(event, json, xhr) {
    authorize_ajax_form_callback(json);
    var task = json;
    jQuery('#errorExplanation').remove();
    jQuery("span.fieldWithErrors").removeClass("fieldWithErrors");
    if (task.status == "error") {
      var html = "<div class='errorExplanation' id='errorExplanation'>";
      html += "<h2>"+ task.messages.length +" error prohibited this template from being saved</h2><p>There were problems with the following fields:</p>";
      for (i=0 ; i < task.messages.length ; i++) {html += "<ul><li>"+ task.messages[i] + "</li></ul>";}
      html += "</div>"
      jQuery(html).insertAfter("#task_id");
    }
    else {
      if (jQuery("#task_list").length) {jQuery("#task_list").trigger("reloadGrid");}
      //update tags
      jQuery("#tags").replaceWith(html_decode(task.tags));
      loadTask(task.tasknum);
      flash_message(task.message);
    }
  }).bind("ajax:before", function(event, json, xhr) {
    if (jQuery("#task_list").length) {
      savejqGridScrollPosition();
    }
    showProgress();
  }).bind("ajax:complete", function(event, json, xhr) {
    hideProgress();
  }).bind("ajax:failure", function(event, json, xhr, error) {
    alert('error: ' + error);
  });
}

function sprint_restoreCollapsedState() {
  if (typeof(localStorage) != 'undefined' && sprint_getCurrentGroup() != 'clear') {
    for (var i = 0; i < localStorage.length; i++){
      var regex = new RegExp("gridgroup_" + sprint_getCurrentGroup() + "_task_listghead_[0-9]+","g");
      if (regex.test(localStorage.key(i)) && localStorage.getItem(localStorage.key(i)) == 'h') {
        var hid = "task_listghead_" + localStorage.key(i).split('_')[4];
        if (jQuery("#" + hid).length) {
          jQuery("#task_list").jqGrid('groupingToggle', hid);
        }
      }
    }
  }
}

function sprint_saveCollapsedStateToLocalStorage(hid, collapsed) {
  if (typeof(localStorage) != 'undefined') {
    if (collapsed) {
      localStorage.setItem("gridgroup_" + sprint_getCurrentGroup() + "_" + hid, 'h');
    }
    else {
      localStorage.removeItem("gridgroup_" + sprint_getCurrentGroup() + "_" + hid);
    }
  }
}

function sprint_getCurrentGroup() {
  if (group_value != "") {
    return group_value;
  } else {
    return jQuery("#sprint_chngroup").val();
  }
}

function sprint_restorejqGridScrollPosition() {
  if (isLocalStorageExist('jqgrid_scroll_position')) {
    jQuery("div.ui-jqgrid-bdiv").scrollTop(getLocalStorage('jqgrid_scroll_position'));
  }
}

function sprint_savejqGridScrollPosition() {
  setLocalStorage("jqgrid_scroll_position", jQuery('div.ui-jqgrid-bdiv').scrollTop());
}



