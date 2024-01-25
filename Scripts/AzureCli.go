package main

import (
	"fmt"
	"os/exec"
	"sync"
)

ClientName := "jokers"
func main() {
	rg := "cyngular" + ClientName + "rg"

	resources := []struct {
		Type string
		Name string
	}{
		{"Microsoft.Storage/storageAccounts", "storageaccount1"},
		{"Microsoft.Compute/virtualMachines", "vm1"},
		// {"Microsoft.Network/virtualNetworks"},
        // {"Microsoft.Network/applicationGateways"},
		
	}

	// Wait group for goroutines
	var wg sync.WaitGroup

	for _, resource := range resources {
		wg.Add(1)
		go func(rType, rName string) {
			defer wg.Done()
			cmd := exec.Command("./create_resource.sh", rg, rType, rName)
			output, err := cmd.CombinedOutput()
			if err != nil {
				fmt.Printf("Error: %v\n", err)
			}
			fmt.Printf("Output: %s\n", output)
		}(resource.Type, resource.Name)
	}

	wg.Wait()

	// az group create --name myResourceGroup --location eastus
	output, err := RunAZCommand("group", []string{"create"}, map[string]string{
		"--name":     "myResourceGroup",
		"--location": "eastus",
	})
	if err != nil {
		fmt.Println("Failed to create resource group:", err)
	} else {
		fmt.Println("Successfully created resource group:", output)
	}
}


// RunAZCommand runs an Azure CLI command and returns its output or error.
func RunAZCommand(mainCmd string, subCmds []string, args map[string]string) (string, error) {
	cmdSlice := []string{mainCmd}

	// Append sub-commands to slice
	cmdSlice = append(cmdSlice, subCmds...)

	// Append arguments to slice
	for k, v := range args {
		cmdSlice = append(cmdSlice, k, v)
	}

	cmd := exec.Command("az", cmdSlice...)

	// Capture output
	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		return "", fmt.Errorf("Error: %s\n%s", err, stderr.String())
	}

	return out.String(), nil
}

// func runAZCommand(command string) error {
// 	cmdArgs := strings.Split(command, " ")

// 	cmd := exec.Command("az", cmdArgs...)
// 	output, err := cmd.CombinedOutput()

// 	if err != nil {
// 		return fmt.Errorf("failed to execute 'az %s': %v\n%s", command, err, string(output))
// 	}
// 	fmt.Printf("Successfully executed 'az %s'\n", command)
// 	return nil
// }