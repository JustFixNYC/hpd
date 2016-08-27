$(document).ready(function() {
  var table = $('#top1000-table').DataTable( {
    "ajax": "data/top1000.txt",
    "columns": [
      { "data": "a" },
      { "data": "zip" },
      { "data": "num" },
      { "data": "nc"},
      //hide the 'id' column; id is used later
      {
        "data": "id",
        "visible": false,
       "searchable": false
      }
    ],
    "order": [[2, "desc"]],
    // enable select and only allow one selection at a time
    "select": {
      "style": 'single'
    }
  });
  // listen for the select event
  table.on( 'select', function ( e, dt, type, index ) {
    // this grabs selected row's id
    var id = table.row(index[0]).data().id;
    var address = table.row(index[0]).data().a;

    names_popup(id, address);
    map(id, '#modal-map', function(map, id){
      add_hq(map, id);
      add_buildings(map, id);
    });
  });

  $('#address-search-btn').click(function(){
    address_popup();
  });
});
