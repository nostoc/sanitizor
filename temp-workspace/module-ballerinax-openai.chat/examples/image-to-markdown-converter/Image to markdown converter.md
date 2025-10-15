# Image to Markdown Converter

This example demonstrates how to convert images containing diagrams, notes, or code snippets into structured markdown documentation using Ballerina connector for OpenAI Chat. The application processes an image file, analyzes its content using GPT-4o-mini vision capabilities, and generates comprehensive markdown documentation with appropriate headings and detailed descriptions.

## Prerequisites

1. **OpenAI Setup**
   - Create an OpenAI account
   - Generate an API key with access to GPT-4o-mini model
   - Ensure you have sufficient credits for API usage

   > Refer the [OpenAI setup guide](https://github.com/ballerina-platform/module-ballerinax-openai.chat/blob/main/ballerina/README.md) here.

2. For this example, create a `Config.toml` file with your credentials. Here's an example of how your `Config.toml` file should look:

```toml
token = "YOUR_OPENAI_API_KEY"
```

## Run the Example

1. Execute the following command to run the example:

```bash
bal run
```

2. When prompted, enter the full path to your image file (e.g., `/path/to/your/image.jpg` or `/path/to/your/diagram.png`). The application will:
   - Process the image and convert it to base64 format
   - Send it to OpenAI's GPT-4o-mini model for analysis
   - Generate structured markdown documentation
   - Save the output as `[original_filename]_documentation.md` in the same directory as the input image

3. Example usage:
```
Enter the path to the image file:
/home/user/documents/architecture_diagram.png
Markdown documentation generated and saved successfully.
```

The generated markdown file will be saved as `architecture_diagram_documentation.md` in the `/home/user/documents/` directory.