// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InvoiceNFT is ERC721, Ownable {

    struct InvoiceData {
        address buyer;
        address supplier;
        uint256 amountWei;
        uint256 dueDate;
        string invoiceRef;
        bool paid;
        bool delivered;
    }

    uint256 public nextID = 1;

    mapping(uint256 => InvoiceData) public invoices;

    event InvoiceCreated (
        uint256 indexed invoiceID,
        address indexed buyer,
        address indexed supplier,
        uint256 amountWei,
        uint256 dueDate,
        string invoiceRef
    );
    event DeliveryConfirmed(uint256 indexed invoiceId, address indexed confirmed);
    event InvoicePaid(uint256 indexed invoiceId, address indexed paid);

    constructor() ERC721("InvoiceNFT", "INVN") Ownable(msg.sender) {}

    function createInvoice(
        address buyer,
        address supplier,
        uint256 amountWei,
        uint256 dueDate,
        string  calldata invoiceRef
    ) external onlyOwner returns (uint256 invoiceId) {
        require (buyer != address(0), "buyer=0");
        require (supplier !=address(0), "supplier=0");
        require (amountWei > 0, "amount=0");
        require (dueDate > block.timestamp, "DueDate in past");

        invoiceId= nextID++;
        _safeMint(supplier, invoiceId);

    invoices[invoiceId] = InvoiceData (
        buyer,
        supplier,
        amountWei,
        dueDate,
        invoiceRef,
        false,
        false
);

        emit InvoiceCreated(invoiceId, buyer, supplier, amountWei, dueDate, invoiceRef);
    }

    function ConfirmDelivery(uint256 invoiceId) external {
        require(_ownerOf(invoiceId) != address(0), "invoice does not exist");
        InvoiceData storage inv = invoices[invoiceId];
        require(!inv.delivered, "already delivered");

        require (
            msg.sender == inv.buyer || msg.sender == owner() || msg.sender == ownerOf(invoiceId), "not authorized"
        );

        inv.delivered = true;
        emit DeliveryConfirmed(invoiceId, msg.sender);
    }

    function markPaid(uint256 invoiceID) external {
        require (_ownerOf(invoiceID) != address(0), "invoice does not exist");
        InvoiceData storage inv = invoices[invoiceID];
        require (inv.delivered, "not delivered yet");
        require (!inv.paid, "already paid");
        require (msg.sender == inv.buyer || msg.sender == owner(), "not authorized");

        inv.paid = true;
        emit InvoicePaid(invoiceID, msg.sender);
    }
}
