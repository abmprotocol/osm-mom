pragma solidity 0.5.12;

import "ds-test/test.sol";

import "osm/osm.sol";
import "./OsmMom.sol";

contract OsmMomCaller {
    OsmMom mom;

    constructor(OsmMom mom_) public {
        mom = mom_;
    }

    function setOwner(address newOwner) public {
        mom.setOwner(newOwner);
    }

    function setAuthority(address newAuthority) public {
        mom.setAuthority(newAuthority);
    }

    function stop(bytes32 ilk) public {
        mom.stop(ilk);
    }
}

contract SimpleAuthority {
    address public authorized_caller;

    constructor(address authorized_caller_) public {
        authorized_caller = authorized_caller_;
    }

    function canCall(address src, address, bytes4) public view returns (bool) {
        return src == authorized_caller;
    }
}

contract OsmMomTest is DSTest {
    OSM osm;
    OsmMom mom;
    OsmMomCaller caller;
    SimpleAuthority authority;

    function setUp() public {
        osm = new OSM(address(this));
        mom = new OsmMom();
        mom.setOsm("ETH-A", address(osm));
        caller = new OsmMomCaller(mom);
        authority = new SimpleAuthority(address(caller));
        mom.setAuthority(address(authority));
        osm.rely(address(mom));
    }

    function testVerifySetup() public {
        assertTrue(mom.owner() == address(this));
        assertTrue(mom.authority() == address(authority));
        assertEq(osm.wards(address(mom)), 1);
    }

    function testSetOwner() public {
        mom.setOwner(address(0));
        assertTrue(mom.owner() == address(0));
    }

    function testFailSetOwner() public {
        // fails because the caller is not the owner
        caller.setOwner(address(0));
    }

    function testSetAuthority() public {
        mom.setAuthority(address(0));
        assertTrue(mom.authority() == address(0));
    }

    function testFailSetAuthority() public {
        // fails because the caller is not the owner
        caller.setAuthority(address(0));
    }

    function testStopAuthorized() public {
        caller.stop("ETH-A");
        assertEq(osm.stopped(), 1);
    }

    function testStopOwner() public {
        mom.stop("ETH-A");
        assertEq(osm.stopped(), 1);
    }

    function testFailStopCallerNotAuthorized() public {
        SimpleAuthority newAuthority = new SimpleAuthority(address(this));  
        mom.setAuthority(address(newAuthority));
        // fails because the caller is no longer authorized on the mom
        caller.stop("ETH-A");
    }

    function testFailStopNoAuthority() public {
        mom.setAuthority(address(0));
        caller.stop("ETH-A");
    }

    function testFailIlkWithoutOsm() public {
        caller.stop("DOGE");
    }
}
