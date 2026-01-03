const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("InvoiceEscrowNFT", function () {
  async function deployFixture() {
    const [owner, buyer, supplier, other] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory("InvoiceEscrowNFT");
    const c = await Factory.deploy();
    await c.waitForDeployment();
    return { c, owner, buyer, supplier, other };
  }

  it("creates an invoice and mints NFT to supplier", async () => {
    const { c, buyer, supplier } = await deployFixture();

    const amount = ethers.parseEther("0.01");
    const dueDate = BigInt(Math.floor(Date.now() / 1000) + 3600);

    const tx = await c.createInvoice(buyer.address, supplier.address, amount, dueDate, "INV-001");
    await tx.wait();

    expect(await c.ownerOf(1)).to.equal(supplier.address);

    const inv = await c.invoices(1);
    expect(inv.buyer).to.equal(buyer.address);
    expect(inv.supplier).to.equal(supplier.address);
    expect(inv.amountWei).to.equal(amount);
    expect(inv.delivered).to.equal(false);
    expect(inv.paid).to.equal(false);
    expect(inv.escrowed).to.equal(0n);
  });

  it("escrows payment only from buyer with exact amount", async () => {
    const { c, buyer, supplier, other } = await deployFixture();

    const amount = ethers.parseEther("0.02");
    const dueDate = BigInt(Math.floor(Date.now() / 1000) + 3600);
    await (await c.createInvoice(buyer.address, supplier.address, amount, dueDate, "INV-002")).wait();

    // Non-buyer cannot escrow
    await expect(
      c.connect(other).escrowPayment(1, { value: amount })
    ).to.be.revertedWith("only buyer");

    // Wrong amount reverts
    await expect(
      c.connect(buyer).escrowPayment(1, { value: ethers.parseEther("0.01") })
    ).to.be.revertedWith("wrong amount");

    // Correct escrow works
    await (await c.connect(buyer).escrowPayment(1, { value: amount })).wait();

    const inv = await c.invoices(1);
    expect(inv.escrowed).to.equal(amount);
  });

  it("releases funds only after delivery confirmation (end-to-end)", async () => {
    const { c, owner, buyer, supplier } = await deployFixture();

    const amount = ethers.parseEther("0.05");
    const dueDate = BigInt(Math.floor(Date.now() / 1000) + 3600);
    await (await c.createInvoice(buyer.address, supplier.address, amount, dueDate, "INV-003")).wait();

    await (await c.connect(buyer).escrowPayment(1, { value: amount })).wait();

    // Can't release before delivery
    await expect(c.connect(owner).releaseFunds(1)).to.be.revertedWith("not delivered");

    // Confirm delivery (supplier can confirm because they own the NFT)
    await (await c.connect(supplier).confirmDelivery(1)).wait();

    // Track supplier balance change on release
    const supplierBalBefore = await ethers.provider.getBalance(supplier.address);
    await (await c.connect(owner).releaseFunds(1)).wait();
    const supplierBalAfter = await ethers.provider.getBalance(supplier.address);

    expect(supplierBalAfter - supplierBalBefore).to.equal(amount);

    const inv = await c.invoices(1);
    expect(inv.paid).to.equal(true);
    expect(inv.escrowed).to.equal(0n);
  });
});
