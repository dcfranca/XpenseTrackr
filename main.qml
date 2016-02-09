import QtQuick 2.5
import QtQuick.Window 2.2
import QtQuick.Layouts 1.1
import Material.ListItems 0.1 as ListItem
import Material 0.2
import Material.Extras 0.1;
import "models.js" as Models
import "utils.js" as Utils

ApplicationWindow {
    title: qsTr("Budget")

    width: 640
    height: 1136
    visible: true
    color: "lightcyan"
    id: root
    property var currencySymbols: ["€", "$", "R$"];
    property string currencySymbol: ""
    property var decimalSeparators: [".", ","];
    property string decimalSeparator: ""
    property int selectedGroupId: -1

    theme {
        primaryColor: Palette.colors["blue"]["500"]
        primaryDarkColor: Palette.colors["blue"]["700"]
        accentColor: Palette.colors["teal"]["500"]
        tabHighlightColor: "white"
    }

    ListModel {
        id: modelBudgetItems
    }

    ListModel {
        id: transactionsModel
    }

    function openTransactionsDialog(categoryId, category, group, parent) {
        transactionsModel.clear()
        var arr = Utils.convertTitleToMonthYear(page.tabs[page.selectedTab])
        var month = arr[0];
        var year = arr[1];
        var baseDate = new Date(year, month, 1);
        var transactions = Utils.retrieveTransactions(baseDate, categoryId);
        for (var x=0; x<transactions.length; x++) {
            var transaction = transactions[x];
            transactionsModel.append({id: transaction.id, name: transaction.name, date: transaction.date, value: transaction.value})
        }

        transDialog.model = transactionsModel
        transDialog.title = group + '/' + category
        console.log("NUMBER OF ELEMENTS: " + transactionsModel.count)
        if (transactionsModel.count > 0) {
            transDialog.open(parent)
        }
    }

    Component {
        id: delegatedBudgetItem

        View {
            id: viewCategory
            width: parent.width
            height: 50
            property alias budgetValue: itemCategory.valueText

            ListItem.Subtitled {
                /*SwipeArea {
                    id: swipeArea
                    anchors.fill: parent
                    onMove: {
                        removeIcon.x += x;

                        if (x > 0 && viewCategory.text.find("    ") === 0) {
                            removeIcon.x = 0;
                        }
                        else if (x < 0 && viewCategory.x < 0) {
                            removeIcon.x = -28;
                        }
                        console.log("REMOVE ICON X: " + removeIcon.x);
                    }

                    onReleased: {
                        console.log("RELEASED!")
                    }

                    onSwipe: {
                        if(direction === "right") {
                            console.log("SWIPE RIGHT")
                            viewCategory.x = 34;
                            removeIcon.x = 0;
                        }
                        else if(direction === "left") {
                            console.log("SWIPE LEFT")
                            viewCategory.x = 0;
                            removeIcon.x = -32;
                        }
                        else {
                            viewCategory.x = 0;
                        }
                    }
                }*/


                id: itemCategory
                height: parent.height
                width: parent.width / 2
                text: category
                valueText: {
                    itemValueLabel.color = (balance >= 0)?'blue':'red'; Utils.formatNumber(balance, currencySymbol, decimalSeparator);
                }

                Component.onCompleted: {
                    Qt.createQmlObject(
                       'import QtQuick 2.0;

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                openTransactionsDialog(categoryId, category, group, root)
                            }
                        }', itemValueLabel
                    )
                }

                secondaryItem: TextField {
                    id: budgetedField
                    placeholderText: "Budgeted"
                    anchors.verticalCenter: parent.verticalCenter
                    text: Utils.formatNumber(''+budget, currencySymbol, decimalSeparator)
                    font.pixelSize: Units.dp(12)
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    horizontalAlignment: TextInput.AlignRight

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            budgetedField.text = Utils.removeCurrencySymbol(budgetedField.text);
                        } else {
                            Models.BudgetItem.filter({id: id}).update({budget: Utils.removeCurrencySymbol(budgetedField.text)});
                            var budgetItem = Models.BudgetItem.filter({id: id}).get()
                            var balanceUpdated = Utils.calculateBudgetBalance(budgetItem, page.tabs[page.selectedTab])
                            itemCategory.valueText = Utils.formatNumber(balanceUpdated, currencySymbol, decimalSeparator)
                            budgetedField.text = Utils.formatNumber(budgetedField.text, currencySymbol, decimalSeparator);
                        }
                    }
                }
                subText: group

                backgroundColor: theme.primaryColor;
                tintColor: theme.tabHighlightColor

                action: Icon {
                    anchors.left: parent.left
                    name: "content/remove_circle"
                    id: removeIcon
                    visible: true
                    size: Units.dp(25)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {

                            var bItem = Models.BudgetItem.filter({id: id}).get();

                            deleteCategoryDialog.category = category
                            deleteCategoryDialog.categoryId = bItem.category
                            deleteCategoryDialog.budgetId = id;
                            deleteCategoryDialog.index = index;
                            deleteCategoryDialog.show();
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: deleteCategoryDialog

        title: "Delete category"
        property string category
        property int categoryId
        property int budgetId
        property int index

        text: "Are you sure you want to delete the category " + category + "?";

        onAccepted: {
            var cat = Models.Category.filter({id: categoryId}).get();

            Models.Category.filter({id: categoryId}).remove();
            Models.BudgetItem.filter({id: budgetId}).remove();
            modelBudgetItems.remove(index);

            if (cat) {
                var categories = Models.Category.filter({categoryGroup: cat.categoryGroup}).all();
                if (categories.length === 0) {
                    var group = Models.Group.filter({id: cat.categoryGroup}).get();
                    deleteGroupDialog.group = group.name;
                    deleteGroupDialog.groupId = group.id;
                    deleteGroupDialog.show();
                }
            }
        }
    }

    Dialog {
        id: deleteGroupDialog

        title: "Delete group"
        property string group
        property int groupId

        text: "The group " + group + " is empty. Do you want to delete it?";

        onAccepted: {
            Models.Group.filter({id: groupId}).remove();
        }
    }

    Dialog {
        id: transDialog

        property alias model: myListView.model
        width: parent.width * 0.8
        height: parent.height * 0.9
        hasActions: false

        ListView {
            id: myListView
            height: contentHeight
            width: contentWidth

            delegate: Component {
                View {
                    width: root.width * 0.7
                    height: 50
                    ListItem.Subtitled {
                        text: name

                        secondaryItem: Text {
                            id: theValue
                            text: new Date(date).toDateString()
                        }

                        valueText: Utils.formatNumber(value, currencySymbol, decimalSeparator)

                        action: Icon {
                            anchors.centerIn: parent
                            name: "content/remove_circle"
                            visible: true
                            size: Units.dp(32)

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    Models.MoneyTransaction.filter({id: id}).remove();
                                    transactionsModel.remove(index)
                                }
                            }
                        }

                    }
                }
            }
        }
    }

    initialPage: TabbedPage {
        id: page
        title: "Budget App"
        tabs: Utils.findMonths()
        //selectedTab: 1

        Component.onCompleted: {
            var arr = Utils.convertTitleToMonthYear(page.tabs[page.selectedTab])
            var month = arr[0]
            var year = arr[1]

            Utils.loadModelBudgetItems(month, year, modelBudgetItems)

        }

        onSelectedTabChanged: {
            console.log("Tab changed: currentMonth: " + page.cur)
            if (typeof page.tabs === 'undefined')
                return;

            var arr = Utils.convertTitleToMonthYear(page.tabs[page.selectedTab])
            var month = arr[0]
            var year = arr[1]

            Utils.loadModelBudgetItems(month, year, modelBudgetItems)
        }

        actions: [
            Action {
                iconName: "action/settings"
                name: "Settings"
                onTriggered: {
                    settings.show();
                }
            }
        ]

        Repeater {
            property var months: page.tabs
            model: page.tabs

            delegate: Tab {
                property string selectedComponent: modelData[1]

                ListView {
                    id: listViewBudgetItems
                    anchors.fill: parent
                    model: modelBudgetItems

                    headerPositioning: ListView.OverlayHeader
                    header: Component {
                        View {
                            id: headerCategory
                            backgroundColor: theme.tabHighlightColor;
                            elevation: 0
                            width: parent.width
                            height: 50

                            Button {
                                text: "New Category"
                                backgroundColor: theme.primaryDarkColor
                                onClicked: categoryDialog.show()
                                anchors.right: parent.right
                            }
                        }
                    }

                    footer: Component {

                        View {
                            id: viewFooter
                            backgroundColor: theme.tabHighlightColor;
                            elevation: 0
                            width: parent.width
                            height: 50

                            TextField {
                                id: checkinAccount
                                placeholderText: "Checkin Account"
                                font.pixelSize: Units.dp(18)
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                horizontalAlignment: TextInput.AlignRight
                                floatingLabel: true

                                Component.onCompleted: {
                                    var dts = Utils.convertTitleToMonthYear(page.tabs[page.selectedTab]);
                                    var checkin = Models.CheckinAccount.filter({month: dts[0]+1, year: dts[1]}).get();
                                    var value = 0;
                                    if (checkin) {
                                        value = checkin.value;
                                    }

                                    checkinAccount.text = Utils.formatNumber(value, currencySymbol, decimalSeparator);
                                }

                                onActiveFocusChanged: {
                                    if (activeFocus) {
                                        checkinAccount.text = Utils.removeCurrencySymbol(checkinAccount.text);
                                    } else {
                                        var dts = Utils.convertTitleToMonthYear(page.tabs[page.selectedTab]);
                                        var value = Utils.removeCurrencySymbol(checkinAccount.text);

                                        if (Models.CheckinAccount.filter({month: dts[0]+1, year: dts[1]}).all().length > 0) {
                                            Models.CheckinAccount.filter({month: dts[0]+1, year: dts[1]}).update({value: value});
                                        }
                                        else {
                                            Models.CheckinAccount.create({month: dts[0]+1, year: dts[1], value: value});
                                        }

                                        checkinAccount.text = Utils.formatNumber(checkinAccount.text, currencySymbol, decimalSeparator);
                                    }
                                }
                            }

                            Label {
                                id: totalBalance
                                text: {
                                    Models.init();
                                    return Utils.formatNumber(Utils.calculateTotalBalance(page.tabs[page.selectedTab], checkinAccount.text), currencySymbol, decimalSeparator)
                                }
                                font.pixelSize: Units.dp(25)
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                            }
                        }
                    }

                    delegate: delegatedBudgetItem
                }
            }
        }

        Button {
            id: btAddTransaction
            text: qsTr("New Transaction")
            elevation: 1
            activeFocusOnPress: true
            backgroundColor: theme.primaryDarkColor
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom

            onClicked: addTransactionDialog.show()
        }

        Dialog {
            id: addTransactionDialog
            title: "New Transaction"

            TextField {
                id: transactionName
                placeholderText: "Name"
                text: 'Transaction'
                font.pixelSize: Units.dp(30)
            }


            TextField {
                id: transactionValue
                placeholderText: "Value"
                text: '0.00'
                font.pixelSize: Units.dp(30)
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                horizontalAlignment: TextInput.AlignRight

                onActiveFocusChanged: {
                    if (!activeFocus) {
                        transactionValue.text = Utils.formatNumber(transactionValue.text, currencySymbol, decimalSeparator);
                    }
                }
            }

            MenuField {
                id: menuAddTransaction
                textRole: "name"

                model: ListModel {
                    id: modelCategories

                    Component.onCompleted: {
                        var groups = Models.Group.all();
                        console.log("GROUPS: " + groups.length);
                        for (var x=0; x < groups.length; x++) {
                            var categories = Models.Category.filter({categoryGroup: groups[x].id}).all();
                            console.log("CATEGORIES: " + categories.length);
                            for (var y=0; y < categories.length; y++) {
                                var name = groups[x].name + '/' + categories[y].name;
                                console.log("name: " + name);
                                modelCategories.append({id: categories[y].id, name: name});
                            }
                        }
                    }
                }
            }

            DatePicker {
                id: transactionDate
            }

            onAccepted: {
                if (!menuAddTransaction.selectedComponent || transactionName.text.length == 0)
                    return;

                var categoryId = menuAddTransaction.selectedComponent.id;
                var d = transactionDate.selectedDate;
                var transaction = Models.MoneyTransaction.create({name: transactionName.text, value: Utils.removeCurrencySymbol(transactionValue.text), category: categoryId, date: Utils.formatDate(d)});
                for (var x=0; x < modelBudgetItems.count; x++) {
                    var item = modelBudgetItems.get(x)
                    var bItem = Models.BudgetItem.filter({id: item.id}).get()
                    if (bItem.category === categoryId) {
                        //WTF?
                        item.budget = Utils.calculateBudgetBalance(bItem, page.tabs[page.selectedTab])
                        var transactions = Utils.retrieveTransactions(d, categoryId)
                        var sum = Utils.sumTransactions(transactions)
                        item.balance = item.budget - sum
                        break;
                    }
                }
            }
        }

        Dialog {
            id: categoryDialog
            title: "New/Edit Category"

            TextField {
                id: categoryValue
                placeholderText: "Category"
                font.pixelSize: Units.dp(30)
            }

            MenuField {
                id: groupSelector
                textRole: "name"
                model: ListModel {
                    id: modelGroups

                    Component.onCompleted: {
                        var groups = Models.Group.all();
                        for (var x=0; x < groups.length; x++) {
                            modelGroups.append({name:groups[x].name, id: groups[x].id});
                        }
                    }
                }

            }

            onAccepted: {
                var category = Models.Category.create({name: categoryValue.text, categoryGroup: groupSelector.selectedComponent.id});
                if (category) {
                    //Create new budget for that
                    var d = new Date();
                    var b = Models.BudgetItem.create({month: d.getMonth()+1, year: d.getFullYear(), category: category.id, budget: 0});
                    var cat = Models.Category.filter({id: b.category}).get();
                    var grp = Models.Group.filter({id: category.categoryGroup}).get();

                    var transactions = Utils.retrieveTransactions(d, category.id)
                    var sum = Utils.sumTransactions(transactions)

                    Utils.loadModelBudgetItems(d.getMonth()+1, d.getFullYear(), modelBudgetItems)
                    //modelBudgetItems.append({id: b.id, budget: b.budget, category: cat.name, categoryId: cat.id, group: grp.name, balance: b.budget-sum});
                }
            }

            Row {
                width: parent.width
                spacing: Units.dp(20)
                Button {
                    text: qsTr("New Group")
                    backgroundColor: theme.primaryDarkColor

                    onClicked: groupDialog.show()
                }
            }
        }

        Dialog {
            id: groupDialog
            title: "New Group"

            TextField {
                id: groupValue
                placeholderText: "Group"
                font.pixelSize: Units.dp(30)
            }

            onAccepted: {
                var group = Models.Group.create({name: groupValue.text});
                if (group) {
                    modelGroups.append(group);
                }
            }
        }

        Dialog {
            id: settings
            title: "Settings"
            height: parent.height / 3

            RowLayout {
                width: parent.width

                Label {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 0.4 * parent.width
                    text: "Currency"
                }

                MenuField {
                    id: selectedCurrency
                    model: currencySymbols
                    maxVisibleItems: 3
                    width: 0.3 * parent.width
                    Component.onCompleted: { currencySymbol = currencySymbols[0]; }

                    onSelectedIndexChanged: {
                        currencySymbol = currencySymbols[selectedIndex];
                    }
                }
            }

            RowLayout {
                width: parent.width

                Label {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 0.4 * parent.width
                    text: "Decimal Separator"
                }

                MenuField {
                    id: decimalSeparatorChoice
                    model: decimalSeparators
                    maxVisibleItems: 2
                    width: 0.3 * parent.width

                    Component.onCompleted: { decimalSeparator = decimalSeparators[0]; }

                    onSelectedIndexChanged: {
                        decimalSeparator = decimalSeparators[selectedIndex];
                    }
                }
            }

        }
    }
}
