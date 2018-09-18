$(function() {
  let getRowsData = function() {
    let data = [];
    $('input[type="checkbox"]:checked').each(function(i, elm) {
      let $input = $(elm),
          $row = $input.closest('#row'),
          rowID,
          rowData;
      if($row.length) {
        rowData = {
          file_id: $row.find('#file_id').text(),
          inputValue: $input.val(),
        };
        data.push(rowData);
      }
    });
    return data;
  };

$('input[id=lefile]').change(function() {
  // $('#select_file').val($(this).files[0].name);
  $('#select_file').val($(this).val().replace("C:\\fakepath\\", ""));
});

$('.predict_confirm').on('click', function(e) {
   let rowsData = getRowsData();
   let s_url = $(this).data("url").replace("0", rowsData[0]['file_id'])
   console.log(s_url);
   console.log(rowsData[0]['file_id']);
   $('#predict_pk').text(rowsData[0]['file_id']);
   $('#predict_url').attr('href', s_url);
});

$('.del_confirm').on('click', function () {
   $("#del_pk").text($(this).data("pk"));
   $('#del_url').attr('href', $(this).data("url"));
});

$('[name=checkbox]').click(function(e){
    e.stopPropagation();
}).parents('tr').click(function(){
    $(this).find('[name=checkbox]').prop('checked', !$(this).find('[name=checkbox]').prop('checked'));
});

$('#all_check_key').click(function(){
  if($('#all_check_key').is(':checked')){
    $('td:first-child input').prop('checked',true);
  }else{
    $('td:first-child input').prop('checked',false);
  };
});
});