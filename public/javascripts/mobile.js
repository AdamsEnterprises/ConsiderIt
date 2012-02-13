var hideClass = "hide";  // for hidden elements

window.onload = function() {
    /*** New point page ***/
//    $("#add_link").click(addLink);
    $j("#point_hide_name").click(warnHideName);

    $j(".cancel").click(function() { history.go(-1); });

    $j("input.has_example")
	.focus(hideExample)
	.blur(setExample)
	.blur();
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

/*
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
*/
function deleteLink() {
  if (confirm("This link will be deleted.")) {
    $j(this).closest(".point_link_form").remove();
  }
}

function deletePoint() {
    var del = confirm("This point will be removed from your list.\n\nDon't worry, though - if you change your mind later, you can always add it back.");

}

function warnHideName() {
    if ($j(this).attr("checked"))
        alert("We encourage you NOT to hide your name. Signing your point with your name " +
            "lends it more weight to other LVG participants.");
}