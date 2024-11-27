/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select StockItemID, 
StockItemName 
from Warehouse.StockItems 
where StockItemName like '%urgent%' or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select S.SupplierID,
SupplierName
from Purchasing.Suppliers S
left join Purchasing.PurchaseOrders O on S.SupplierID = O.SupplierID
where PurchaseOrderID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

select
O.OrderID,
format(O.OrderDate, 'dd-MM-yyyy') OrderDate ,
datename(month, O.OrderDate)  Месяц,
datepart(quarter, O.OrderDate) Квартал,
Case 
When month(O.OrderDate) <= 4  Then 1 
When month(O.OrderDate) >= 9 Then 3
Else 2 
End [Треть года],
S.CustomerName
from Sales.Orders O
left join Sales.OrderLines OL on O.OrderID=OL.OrderID
left join Sales.Customers S on O.CustomerID=S.CustomerID
where UnitPrice>100 or Quantity > 20 and O.PickingCompletedWhen is not null
order by Квартал, [Треть года], O.OrderDate 
OffSet 1000 Rows
Fetch Next 100 rows ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select D.DeliveryMethodName, PO.ExpectedDeliveryDate, S.SupplierName, P.FullName
from Purchasing.Suppliers S
left join Purchasing.PurchaseOrders PO on S.SupplierID = PO.SupplierID
left join Application.DeliveryMethods D on D.DeliveryMethodID = S.DeliveryMethodID
left join Application.People P on P.PersonID = PO.ContactPersonID
where 
format(PO.ExpectedDeliveryDate, 'MM.yyyy') = '01.2013' 
and (D.DeliveryMethodName = 'Air Freight' or D.DeliveryMethodName = 'Refrigerated Air Freight')
and PO.IsOrderFinalized  = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и Sименем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select top 10
OrderDate,
C.CustomerName,
P.FullName
from Sales.Orders O
left join Sales.Customers C on O.CustomerID=C.CustomerID
left join Application.People P on O.SalespersonPersonID=P.PersonID
order by OrderDate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select C.CustomerID,
C.CustomerName,
C.PhoneNumber,
W.StockItemName
from Sales.OrderLines OL
left join Sales.Orders O on O.OrderID = OL.OrderID
left join Sales.Customers C on O.CustomerID = C.CustomerID
Left join Warehouse.StockItems W on OL.StockItemID = W.StockItemID
where W.StockItemName = 'Chocolate frogs 250g'