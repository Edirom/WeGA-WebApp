function checkAllBoxes(id, checked) {
    var form = $(id).select('[class="itemCheckbox"]');
    if (checked == true)
        {checked = true}
        else {checked = false}
    for (var i=0 ; i < form.length ; i++) 
	{form[i].checked = checked;}
};

function filterByYear() {
    var checkboxes = $('formYear').select('input[class="itemCheckbox"]');
    for (var i=0 ; i < checkboxes.length ; i++) {
         var str = '.pubYear' + checkboxes[i].value;
         if(checkboxes[i].checked == true)
            {
                $$(str).invoke('addClassName', 'yearVisible');
                $$(str + '.journalVisible').invoke('show');
            }
            else {
                $$(str).invoke('removeClassName', 'yearVisible');
                $$(str).invoke('hide');
            }
    };
};

function filterByJournal() {
    var checkboxes = $('formJournal').select('input[class="itemCheckbox"]');
    for (var i=0 ; i < checkboxes.length ; i++) {
         var str = '.journal' + checkboxes[i].value;
         if(checkboxes[i].checked == true)
            {
                $$(str).invoke('addClassName', 'journalVisible');
                $$(str + '.yearVisible').invoke('show');
            }
            else {
                $$(str).invoke('removeClassName', 'journalVisible');
                $$(str).invoke('hide');
            }
    };
};