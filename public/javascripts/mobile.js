window.onload = function() {

    // New point page
    $j("#add_link").click(addLink);
    $j("#point_hide_name").click(warnHideName);

    // "Remove point" button
    $j(".remove_point").click(confirmRemovePoint);
    // "Delete point" button
    $j(".delete_point").click(confirmDeletePoint);

    // Cancel/back buttons and links
    $j(".back").click(function() { history.back(); return false; });

    // Textboxes with watermark
    $j(".has_example")
        .focus(hideExample)
        .blur(setExample)
        .blur();
    
    // Textboxes with character limit
    $j("textarea.char_limit").keyup(adjustCharLimit);

    // Signup pledge page
    $j("#pledge_agree").click(togglePledgeSubmit);
}

function adjustCharLimit() {
    var textarea = $j(this);
    var limit = textarea.attr("count");
    var length = textarea.val().length;
    if (length > limit) {
        // Prevent character from being added
        textarea.val(textarea.val().substr(0,limit));
        // Play alert sound. Should probably remove old sound
        // elements to keep things clean, but it seems like this
        // slows things down slightly.
        $j("body").append('<embed src="tonk.wav" autostart="true" loop="false" ' +
			  'style="visibility:hidden;" />');
    } else {
        textarea.siblings(".count")
            .text("Remaining characters: " + (limit - length));
    }
}

// For textboxes with watermark text when empty
function setExample() {
    var input = $j(this);
    if (input.val() == "") {
        input.addClass("example")
        input.val(input.attr("title"));
    }
}
function hideExample() {
    var input = $j(this);
    if (input.hasClass("example")) {
        input.removeClass("example");
        input.val("");
    }
}

LinkCount = 0

function addLink() {
  
  var fieldset = $j("<fieldset />")
    .append($j("<div>")
              .addClass("delete")
              .addClass("clickable")
              .click(deleteLink)
              .text("delete"))
    .append($j("<input />")
              .attr("type", "text")
              .attr("id", "point_point_links_attributes_" + LinkCount + "_url")
              .attr("name", "point[point_links_attributes][" + LinkCount + "][url]")
              .attr("title", "http://...")
              .addClass("has_example")
              .blur(setExample)
              .focus(hideExample)
              .blur())
    .append($j("<input />")
              .attr("type", "text")
              .attr("id", "point_point_links_attributes_" + LinkCount + "_description")
              .attr("name", "point[point_links_attributes][" + LinkCount + "][description]")
              .attr("title", "A brief description")
              .addClass("has_example")
              .blur(setExample)
              .focus(hideExample)
              .blur());    
  $j("<div/>")
    .addClass("point_link_form")
    .append(fieldset)
     .appendTo($j("#point_links"));

  LinkCount++;

  return false;
}

function deleteLink() {
    if (confirm("This link will be deleted.")) {
        $j(this).closest(".point_link_form").remove();
    }
}

function confirmRemovePoint() {
    return confirm("This point will be removed from your list.");
}

function confirmDeletePoint() {
    return confirm("This point will be permanently deleted and cannot be added again.");
}

// When the user checks/unchecks the box agreeing to the conditions
// of the site pledge, enable/disable the button to go to the
// signup page accordingly
function togglePledgeSubmit() {
    var signup = $j("#pledge_submit");  // signup button
    if ($j(this).attr("checked"))
        signup.attr("disabled", null);
    else
        signup.attr("disabled", "disabled");
}

function warnHideName() {
    if ($j(this).attr("checked"))
        alert("We encourage you NOT to hide your name. Signing your point with your name " +
            "lends it more weight to other LVG participants.");
}

