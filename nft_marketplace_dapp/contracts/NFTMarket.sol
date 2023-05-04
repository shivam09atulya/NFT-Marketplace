// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is
    ERC721URIStorage //we inherit from ERC721URIStorage
{
    using Counters for Counters.Counter; //Counters.Counter is a variables from counters
    Counters.Counter private _tokenIds; // total number of items ever created
    Counters.Counter private _itemsSold; // total number of item sold

    uint256 listingPrice = 0.001 ether; //people have to pay to list their nft //listing fees
    address payable owner; // owner of the smart contract

    constructor() ERC721("Metaverse Tokens", "META") {
        owner = payable(msg.sender); //In Solidity, msg is a global variable that contains information about the current function call, including the sender address (msg.sender), the amount of ether (msg.value) sent with the function call, and other data.
        // In this specific line of code, owner is being assigned to the payable address of msg.sender. msg.sender is the address of the person or contract that initiated the current function call, which in this case is the seller of the item.
        // The payable keyword is used to indicate that the owner address can receive ether, as it is declared as an address payable in the MarketItem struct.
        // Therefore, this line of code assigns the owner of the MarketItem to the payable address of the person or contract that initiated the function call, which is the seller.
    }

    mapping(uint256 => MarketItem) private idToMarketItem;
    // mapping(uint256 => MarketItem) private idToMarketItem is a data structure in the Solidity programming language that allows you to create a one-to-one relationship between two types of data - in this case, a uint256 (which is an unsigned integer) and a MarketItem struct.
    // This means that for each uint256 value (which can be thought of as a unique ID number), we can store a corresponding MarketItem struct that contains information about an item for sale in a marketplace.
    // For example, let's say we have an NFT marketplace and there are 10 NFTs being sold. Each NFT has a unique tokenId, which could be any positive integer value. We can use the mapping to associate each tokenId with a MarketItem struct that contains information about the NFT, such as the seller, owner, price, and whether or not it has been sold.
    // So, if someone wants to buy a specific NFT, we can look up its tokenId in the idToMarketItem mapping to find the corresponding MarketItem struct that contains all the necessary information to complete the transaction.
    // Overall, mapping(uint256 => MarketItem) private idToMarketItem provides an efficient and convenient way to store and retrieve information about items for sale in a decentralized marketplace.
    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }
    //Imagine you have a toy that you want to sell to someone. To do this, you need to tell them how much you want for the toy and give them the toy when they pay you. The MarketItem is like a special piece of paper that has all the important information about the toy and the person who is selling it. This paper says what the toy is, how much it costs, and who is selling it.
    //The idToMarketItem part is like a big book where we write down all the important papers for all the toys that people want to sell. So when someone wants to buy a toy, we can look in the big book to find the paper that has all the important information about that toy.
    //Overall, this code is like a way for people to keep track of all the important information about the toys they want to sell, so that other people can easily find and buy the toys they want.

    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    // Returns the listing price of the market
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    //update the listing price, this can only be done by the owner
    //A payable function in Solidity is a function that can receive Ether and respond to an Ether deposit for record-keeping purposes.
    function updateListingPrice(uint _listingPrice) public payable {
        require(
            owner == msg.sender,
            "Only market place owner can update listing price"
        );
        listingPrice = _listingPrice;
    }

    //this function creates the marketitem and then stores it in the idtoMarketItem thats why its private
    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be greater than zero");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );
        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        _transfer(msg.sender, address(this), tokenId);
        // _transfer is a function that transfers ownership of an ERC-721 token from one address to another. In this case, msg.sender (the address of the person calling the function) is transferring ownership of the token with ID tokenId to address(this), which is the address of the smart contract.
        // This transfer is being made to put the token in escrow, which means that the token is held by the smart contract until the buyer purchases it. By transferring ownership to the smart contract, the seller ensures that they cannot transfer or sell the token until it has been purchased by someone else.
        // This function is typically used in NFT marketplaces or other systems where ownership of a token needs to be temporarily transferred to a trusted third party until a transaction is completed.
        //This transfers the nft to the blockchain
        emit MarketItemCreated( //emit stores the arguments passed in transaction log
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    //Mints a token and lists it in the marketplace
    function createToken(
        string memory tokenURI,
        uint256 price
    ) public payable returns (uint) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price);
        return newTokenId;
    }

    // creating the sale of a marketplace item
    // Transfers ownership of the item as well as funds
    function createMarketSale(uint256 tokenId) public payable {
        uint price = idToMarketItem[tokenId].price;
        address seller = idToMarketItem[tokenId].seller;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );
        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].sold = true;
        idToMarketItem[tokenId].seller = payable(address(0));
        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);
        payable(owner).transfer(listingPrice); //%%%%%%%%%%%%%%%%%%%%%%  Owner being changed here
        payable(seller).transfer(msg.value);
    }

    // Returns all unsold market items
    // This is a Solidity function in a smart contract that fetches all unsold market items that are currently listed for sale.
    // The function starts by getting the total number of NFTs in the market (stored in the _tokenIds counter), and the number of unsold NFTs (calculated by subtracting the number of sold items from the total). It also initializes a variable called currentIndex to keep track of the current index in the array of MarketItem objects being constructed.
    // The function then creates a new array of MarketItem objects with a size equal to the number of unsold items. It then loops through all NFTs, checking if each NFT is currently owned by the market smart contract (indicated by the owner field in the MarketItem struct). If an NFT is owned by the market contract, the function gets the MarketItem object for that NFT and adds it to the array of unsold items.
    // Finally, the function returns the array of unsold MarketItem objects.
    // Overall, this function is useful for allowing users to see all currently available market items that they can purchase or bid on, without having to search through all NFTs that may have already been sold.

    //Itemes which are unsold
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _tokenIds.current();
        uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this)) {
                // %%%%%%%%%%%%%% so if address is same then the item is unsold otherwise unsold
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Returns only items that a user has purchased
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                //change only here , rest almost same for this and the function below
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            //total items purchased by the user
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Returns only items that a user has listed
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                //here it is seller and not owner , so all the items it made as seller
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Allows user to resell a token they have purchased
    function resellToken(uint256 tokenId, uint256 price) public payable {
        require(
            idToMarketItem[tokenId].owner == msg.sender, //Owenr should be the seller otherwise how could he sell anyone else's nft
            "Only item owner can perform this operation"
        );
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        _itemsSold.decrement();
        _transfer(msg.sender, address(this), tokenId);
    }

    // Allows user to cancel their market listing
    function cancelItemListing(uint256 tokenId) public {
        require(
            idToMarketItem[tokenId].seller == msg.sender,
            "Only item seller can perform this operation"
        );
        require(
            idToMarketItem[tokenId].sold == false,
            "Only cancel items which are not sold yet"
        );
        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].seller = payable(address(0));
        idToMarketItem[tokenId].sold = true;
        _itemsSold.increment();
        payable(owner).transfer(listingPrice);
        _transfer(address(this), msg.sender, tokenId);
    }
}
