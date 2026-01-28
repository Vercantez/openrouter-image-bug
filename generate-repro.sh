#!/bin/bash

# Generate the repro JSON with the test image embedded as base64

if [[ "$OSTYPE" == "darwin"* ]]; then
    BASE64_IMAGE=$(base64 -b 0 < test.jpg)
else
    BASE64_IMAGE=$(base64 -w 0 < test.jpg)
fi

cat > repro.json << HEREDOC
{
  "model": "claude-opus-4-5-20251101",
  "max_tokens": 1024,
  "tools": [
    {
      "name": "read_image",
      "description": "Read an image file from disk",
      "input_schema": {
        "type": "object",
        "properties": {
          "path": {
            "type": "string",
            "description": "Path to the image file"
          }
        },
        "required": ["path"]
      }
    }
  ],
  "messages": [
    {
      "role": "user",
      "content": "Read the image at test.jpg and describe what you see"
    },
    {
      "role": "assistant",
      "content": [
        {
          "type": "tool_use",
          "id": "toolu_01ABC123",
          "name": "read_image",
          "input": {
            "path": "test.jpg"
          }
        }
      ]
    },
    {
      "role": "user",
      "content": [
        {
          "type": "tool_result",
          "tool_use_id": "toolu_01ABC123",
          "content": [
            {
              "type": "image",
              "source": {
                "type": "base64",
                "media_type": "image/jpeg",
                "data": "$BASE64_IMAGE"
              }
            }
          ]
        }
      ]
    }
  ]
}
HEREDOC

echo "Generated repro.json"
