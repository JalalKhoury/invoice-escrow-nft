// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract invoiceEscrowNFT is ERC721, Ownable, ReentrancyGuard {

    struct invoicedata {
        address buyer;
        address supplier;
        uint256 amountWei;
        uint256 duedate;
        string invoiceref;

        bool paid;
        bool delivered;
        uint256 escrowed;
    }

    uint256 public nextID=1;

    mapping(uint256 => invoicedata) public invoices;

    event InvoiceCreated (
        uint256 indexed invoiceid,
        address indexed buyer,
        address indexed supplier,
        uint256 amountWei,
        uint256 duedate,
        string invoiceref
    );

    event DeliveryConfirmed(uint256 indexed invoiceid, address indexed confirmed);
    event InvoicePaid(uint256 indexed invoiceid,address indexed buer, uint256 amountWei);
    event FundsReleased(uint256 indexed inoiceid, address indexed supplier, uint256 amountWei);

    constructor() ERC721("invoiceEscrowNFT", "INVN") Ownable(msg.sender) {}

    function createInvoice (
        address buyer,
        address supplier,
        uint256 amountWei,
        uint256 duedate,
        string calldata invoiceref
    ) external onlyOwner returns (uint256 invoiceid){
        require(buyer !=address(0), "buyer=0");
        require(supplier !=address(0), "supplier=0");
        require(amountWei>0, "amount=0");
        require(duedate>block.timestamp, "DueDate in past");

        invoiceid= nextID++;
        _safeMint(supplier,invoiceid);

        invoices[invoiceid] = invoicedata (
            buyer,
            supplier,
            amountWei,
            duedate,
            invoiceref,
            false,
            false,
            0
        );

        emit InvoiceCreated(invoiceid, buyer, supplier, amountWei, duedate, invoiceref);
    }

    function confirmDelivery (uint256 invoiceid) external {
        require(_ownerOf(invoiceid) !=address(0), "invoice does not exist");
        invoicedata storage inv = invoices[invoiceid];
        require(!inv.delivered, "already delivered");
        require(inv.escrowed == inv.amountWei, "payment not escrowed");
        require(msg.sender == inv.buyer || msg.sender == owner() || msg.sender == owner(), "not authorized");

        inv.delivered= true;
        
        emit DeliveryConfirmed(invoiceid, msg.sender);
    }

    function markPaid(uint256 invoiceid) external payable nonReentrant {
        require(_ownerOf(invoiceid) != address(0), "invoice does not exist");
        invoicedata storage inv = invoices[invoiceid];
        require(msg.sender == inv.buyer, "only buyer");
        require(!inv.paid, "already paid");
        require(inv.escrowed == 0, "already escrowed");
        require(msg.value == inv.amountWei, "wrong amount");
        
        inv.escrowed= msg.value;
        emit InvoicePaid(invoiceid, msg.sender, msg.value);
    }

    function releaseFunds(uint256 invoiceid) external onlyOwner nonReentrant {
        require(_ownerOf(invoiceid) != address(0), "invoice does not exist");
        invoicedata storage inv= invoices[invoiceid];
        require(inv.delivered, "not delivered");
        require(!inv.paid, "already paid");
        require(inv.escrowed == inv.amountWei, "no escrow");

        uint256 amount = inv.escrowed;

        inv.escrowed = 0;
        inv.paid = true;

        (bool success,) = inv.supplier.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit FundsReleased(invoiceid, inv.supplier, amount);
    }
}
