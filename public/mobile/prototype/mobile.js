var hideClass = "hide";  // for hidden elements

window.onload = function() {
    $(".expander").click(toggleText);
    
    // Controls for points on user's pro/con list
    $(".delete_point").click(deletePoint);
    $(".point_up").click(moveUp);
    $(".point_down").click(moveDown);
    
    // Textboxes with placeholder text
    $(".has_example")
      .blur(showPlaceholder)
      .focus(hidePlaceholder)
      .blur();
    
    /*** New point page ***/
    $("#add_link").click(addLink);
    $("#point_hide_name").click(warnHideName);
    
    /*** All opinions page ***/
    $(".stance_chart div").click(showVoterSegmentPoints);
    $("#show_user_points").click(showUserPoints);
    $("#show_overall_points").click(showOverallPoints);
}

function addLink() {
  var fieldset = $("<fieldset />")
    .append($("<div>")
              .addClass("delete")
              .addClass("clickable")
              .click(deleteLink)
              .text("delete"))
    .append($("<input />")
              .attr("type", "text")
              .attr("size", "30")
              .attr("id", "point_point_links_attributes_longcrazynumber_url")
              .attr("title", "http://...")
              .addClass("has_example")
              .addClass("example")
              .blur(showPlaceholder)
              .focus(hidePlaceholder)
              .blur())
    .append($("<input />")
              .attr("type", "text")
              .attr("size", "30")
              .attr("id", "point_point_links_attributes_longcrazynumber_description")
              .attr("title", "A brief description")
              .addClass("has_example")
              .addClass("example")
              .blur(showPlaceholder)
              .focus(hidePlaceholder)
              .blur());    
  $("<div/>")
    .addClass("point_link_form")
    .append(fieldset)
    .appendTo(".point_link_block");
}

function deleteLink() {
  if (confirm("This link will be deleted.")) {
    $(this).closest(".point_link_form").remove();
  }
}

function deletePoint() {
    var del = confirm("This point will be removed from your list.\n\nDon't worry, though - if you change your mind later, you can always add it back.");
    
    if (del) {
        var li = $(this).closest("li");
        var ul = li.parent();
        li.remove();
        
        // Reestablish odd/even striping
        var points = ul.children();
        for (var i = 0; i < points.length(); i++) {
            if (i % 2 == 0) {
                $(points.get(i)).removeClass("even");
            } else {
                $(points.get(i)).addClass("even");
            }
        }
    }
}

function hidePlaceholder() {
  var elt = $(this);
  if (elt.val() == elt.attr("title")) {
    elt.removeClass("example");
    elt.val("");
  }
}

// For rearranging points in your pro/con list
function moveUp() {
  var li = $(this).closest("li");
  var prev = li.prev();
  if (prev.length > 0) {
    li.remove().insertBefore(prev);
    li.toggleClass("even");
    prev.toggleClass("even");
    
    // Reattach event listeners
    li.find(".point_up").click(moveUp);
    li.find(".point_down").click(moveDown);
  }
}

// For rearranging points in your pro/con list
function moveDown() {
  var li = $(this).closest("li");
  var next = li.next();
  if (next.length > 0) {
    li.remove().insertAfter(next);
    li.toggleClass("even");
    next.toggleClass("even");
    
    // Reattach event listeners
    li.find(".point_up").click(moveUp);
    li.find(".point_down").click(moveDown);
  }
}

function showPlaceholder() {
  var elt = $(this);
  if (elt.val() == "") {
    elt.addClass("example");
    elt.val(elt.attr("title"));
  }
}

function showOverallPoints() {
    $("#points_header h2")
        .addClass("hide")
        .filter(".all_points").removeClass("hide");
}

function showUserPoints() {
    $("#points_header h2")
        .addClass("hide")
        .filter(".user_points").removeClass("hide");
}

function showVoterSegmentPoints() {
    var segment_name = $(this).attr("segment");
    console.log(segment_name);
    $("#points_header h2")
        .addClass("hide")
        .filter(".segment_points").removeClass("hide")
        .find(".voter_segment").text(segment_name);
}

function toggleText() {
  var text = $(this).parent().siblings(".expandable");
  if (text.hasClass(hideClass))
    $(this).text("hide");
  else
    $(this).text($(this).attr("origText"));
  text.toggleClass(hideClass);
}

function warnHideName() {
    if ($(this).attr("checked"))
        alert("We encourage you NOT to hide your name. Signing your point with your name " +
            "lends it more weight to other LVG participants.");
}