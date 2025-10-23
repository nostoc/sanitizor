## High-Level Workflow
The Example Generator will work as an independent Ballerina package that you can run after the sanitizor has created the base client. Its primary goal is to create one or more meaningful, multi-step examples that showcase the connector's functionality.

The workflow for generating a single example will be as follows:

1. Analyze: The tool first determines how many examples to create by counting the number of API operations in client.bal. Can count number of remote and resource keywords in the client.bal/

2. Generate Use Case: It prompts the LLM to invent a realistic use case based on the available API operations (e.g., "create a user, then fetch their profile").

3. Generate Code: It then prompts the LLM again, this time to write the full Ballerina code for that use case.

4. Fix and Verify: The generated code is saved to a file, and your Code Fixer module is invoked on it. The fixer will run in a loop until the code is free of compilation errors.

5. Finalize: The error-free example code is saved into the connector's /examples directory, ready for use.