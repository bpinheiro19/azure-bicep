#!/bin/bash
az group create -g aks-rg -l swedencentral
az deployment group create --resource-group aks-rg --template-file main.bicep