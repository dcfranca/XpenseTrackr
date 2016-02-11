var definedMonths = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
var definedMonthDays = {"Jan": 31, "Feb": 29, "Mar": 31, "Apr": 30, "May": 31, "Jun": 30, "Jul": 31, "Aug": 31, "Sep": 30, "Oct": 31, "Nov": 30, "Dec": 31};

//Database: ~/Library/Application Support/BudgetApp/QML/OfflineStorage/Databases

function formatDate(date) {
    var str = date.toISOString();
    return str.substring(0, 10)
}

function convertTitleToMonthYear(title) {

    console.log("convertTitleToMonthYear:TITLE: " + title);

    if (title === undefined) {
        return;
    }

    var splittedDate = title.split('/');
    var monthName = splittedDate[0];
    var month = definedMonths.indexOf(monthName) + 1;
    var year = parseInt(splittedDate[1]);

    return [month-1, year];
}

function getStartAndEndDate(date) {

    var month = date.getMonth()+1;
    var year = date.getFullYear();

    var monthName = definedMonths[month-1];
    var endDay = definedMonthDays[monthName];

    if (month < 10) {
        month = '0' + month;
    }
    if (endDay < 10) {
        endDay = '0' + endDay;
    }

    var startDate = year + '-' + month + '-01';
    var endDate = year + '-' + month + '-' + endDay;

    return [startDate, endDate];
}

function retrieveTransactions(date, category) {
    var limitDates = getStartAndEndDate(date);
    var startDate = limitDates[0];
    var endDate = limitDates[1];

    if (category) {
        return Models.MoneyTransaction.filter({category: category, date__ge: startDate, date__le: endDate}).all();
    }
    else {
        return Models.MoneyTransaction.filter({date__ge: startDate, date__le: endDate}).all();
    }
}

function retrieveBudgetItems(date) {
    return Models.BudgetItem.filter({month: date.getMonth()+1, year: date.getFullYear()}).all();
}

function sumBudgetItems(date) {
    var items = retrieveBudgetItems(date);
    var total = 0;
    for (var x=0; x < items.length; x++) {
        total += items[x].budget;
    }

    return total;
}

function sumTransactions(transactions) {
    var sum = 0;
    for (var x=0; x<transactions.length; x++) {
        sum += convertToNumber(transactions[x].value);
    }
    return sum;
}

function calculateBudgetBalance(budgetItem, title) {

    //TODO: Change it to a SUM aggregation function call
    console.log("calculateBudgetBalance: TITLE: " + title)
    var dates = convertTitleToMonthYear(title)
    var date = new Date(dates[1], dates[0], 1)
    var transactions = retrieveTransactions(date, budgetItem.category)
    var totalSpent = sumTransactions(transactions);
    console.log("BUDGET SPENT: " + totalSpent)

    var balance = budgetItem.budget - totalSpent;

    console.log("BUDGET BALANCE: " + balance)

    return balance;
}

function calculateTotalBalance(title, checkin) {

    //TODO: Change it to a SUM aggregation function call
    console.log("calculateTotalBalance: TITLE: " + title);
    console.log("CHECKIN BEFORE PARSE: " + checkin)
    checkin = parseInt(removeCurrencySymbol(checkin))

    console.log("CHECKIN: " + checkin)
    if (!checkin) {
        checkin = 0;
    }
    console.log("1 - PARAM TITLE: "+title);
    var dates = convertTitleToMonthYear(title)
    var date = new Date(dates[1], dates[0], 1)
    var transactions = retrieveTransactions(date)
    var totalSpent = sumTransactions(transactions);
    console.log("TOTAL SPENT: " + totalSpent)

    var balance = checkin - totalSpent;

    console.log("BALANCE: " + balance)

    return balance;
}


function convertToNumber(value) {
    if (typeof value === "number") return value;

    return parseInt(removeCurrencySymbol(value.replace(',','.')));
}

function createMonthTitle(monthIndex, currentYear) {
    return definedMonths[monthIndex] + '/' + currentYear;
}

function findMonths(date, indexes) {
    var months = [];

    if (!date) {
        date = new Date();
    }

    if (typeof indexes === 'undefined') {
        indexes = [-1, 0, 1];
    }

    var monthIndex = date.getMonth();
    var currentYear = date.getFullYear();

    for (var x=0; x<indexes.length; x++) {
        var idxMonth = monthIndex + indexes[x];
        var titleYear = currentYear;

        if (idxMonth > 11) {
            while (idxMonth > 0) {
                idxMonth -= 12;
                titleYear++;
            }
        } else if (idxMonth < 0) {
            while (idxMonth < 11) {
                idxMonth += 12
                titleYear--;
            }
        }

        months.push(createMonthTitle(idxMonth, titleYear));
    }

    return months;//.reverse();
}

function removeCurrencySymbol(value) {
    if (value.indexOf(' ') === -1) {
        return value;
    }
    var sp = value.split(' ');
    return sp[sp.length-1].trim();
}

function formatNumber(value, currencySymbol, decimalSeparator) {
    var allowedAfterSeparator = 2;
    var afterSeparator = -1;
    var finalValue = '';
    var begin = true;

    value += ''; //Convert number to string

    for (var x=0; x < value.length; x++) {
        //End
        if (afterSeparator >= allowedAfterSeparator) {
            break;
        }
        //IsNumber
        else if (!isNaN(value[x])) {
            if (!begin || value[x] !== '0') {
                finalValue += value[x];
                begin = false;
            }
            if (afterSeparator >= 0) {
                afterSeparator += 1;
            }
        }
        //IsSeparator
        else if (value[x] === decimalSeparator) {
            if (finalValue.length === 0) {
                finalValue = '0';
            }

            finalValue += decimalSeparator;
            afterSeparator += 1;
        }
        //Is minus
        else if (value[x] === '-') {
            finalValue += '-'
        }
    }

    if (finalValue.length === 0) {
        finalValue = '0';
    }

    if (afterSeparator >= -1) {
        finalValue += (decimalSeparator + '00').substring(afterSeparator + 1);
    }

    return currencySymbol + ' ' + finalValue;
}

function loadModelBudgetItems(month, year, modelBudgetItems) {
    modelBudgetItems.clear()

    //Load from the database
    //Find all categories
    var categories = Models.Category.order('categoryGroup').all();
    for (var i=0; i<categories.length; i++) {
        var category = categories[i];
        var budItem = Models.BudgetItem.filter({month: month+1, year: year, category: category.id}).get();

        if (!budItem) {
            //In the DB month is 1-index
            budItem = Models.BudgetItem.create({budget:0, category: category.id, month: month+1, year: year})
        }

        var group = Models.Group.filter({id: category.categoryGroup}).get();
        var budget = budItem.budget;
        if (!budget) {
            budget = 0;
        }

        var baseDate = new Date(year, month, 1);
        var transactions = Utils.retrieveTransactions(baseDate, category.id)
        var sum = Utils.sumTransactions(transactions)
        modelBudgetItems.append({id: budItem.id, budget: budget, category: category.name, categoryId: category.id, group: group.name, balance: budget-sum});
    }
}

