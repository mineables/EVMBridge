#!/usr/bin/env bash

rm -rf flats/*

truffle-flattener contracts/ERC20Portal.sol > flats/ERC20Portal.sol
truffle-flattener contracts/NativePortal.sol > flats/NativePortal.sol
truffle-flattener contracts/HomeToken.sol > flats/HomeToken.sol