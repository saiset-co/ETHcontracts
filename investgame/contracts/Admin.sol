// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";


abstract contract Admin is Context {
    address private _admin;

    bool inited = false;


    constructor() {
        _transferAdminship(_msgSender());
    }

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }

    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    function _checkAdmin() internal view virtual {
        require(admin() == _msgSender(), "Admin: caller is not the admin");
    }


    function transferAdminship(address newAdmin) public virtual onlyAdmin {
        require(newAdmin != address(0), "Admin: new Admin is the zero address");
        _transferAdminship(newAdmin);
    }

    function _transferAdminship(address newAdmin) internal virtual {
        _admin = newAdmin;
    }
}
