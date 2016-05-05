/*
GreedyNav.js - http://lukejacksonn.com/actuate
Licensed under the MIT license - http://opensource.org/licenses/MIT
Copyright (c) 2015 Luke Jackson
*/

$.fn.greedyNav = function() {

  var $btn = $('nav.greedy button'),
      $vlinks = $('nav.greedy .links'),
      $hlinks = $('nav.greedy .hidden-links'),
      
      numOfItems = 0,
      totalSpace = 0,
      breakWidths = [],
      
      availableSpace, numOfVisibleItems, requiredSpace;

  // Get initial state
  $vlinks.children(':visible').outerWidth(function(i, w) {
    totalSpace += w;
    numOfItems += 1;
    breakWidths.push(totalSpace);
  });
  
  
  function check() {

    // Get instant state
    availableSpace = $vlinks.width() - 10;
    numOfVisibleItems = $vlinks.children(':visible').length;
    requiredSpace = breakWidths[numOfVisibleItems - 1];

    // There is not enought space
    if (requiredSpace > availableSpace) {
      $vlinks.children(':visible').last().prependTo($hlinks);
      numOfVisibleItems -= 1;
      check();
      // There is more than enough space
    } else if (availableSpace > breakWidths[numOfVisibleItems]) {
      $hlinks.children().first().appendTo($vlinks);
      numOfVisibleItems += 1;
    }
    // Update the button accordingly
    $btn.attr("count", numOfItems - numOfVisibleItems);
    if (numOfVisibleItems === numOfItems) {
      $btn.addClass('hidden');
    } else $btn.removeClass('hidden');
  };

  // Window listeners
  $(window).resize(function() {
    check();
  });

  $btn.on('click', function() {
    $hlinks.toggleClass('hidden');
  });
  
  $vlinks.on('click', function() {
    $hlinks.addClass('hidden');
  });

  check();

};
