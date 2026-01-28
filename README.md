# OpenRouter Bug: Images in tool_result are corrupted/ignored

## Summary

When sending an image inside a `tool_result` content block to OpenRouter's `/api/v1/messages` endpoint (Anthropic-compatible), the model hallucinates and describes a completely different image than what was sent. The same request works correctly when sent directly to Anthropic's API.

## The Image

This is `cat.jpg` - an orange tabby cat:

![cat.jpg](cat.jpg)

## The Bug

When this image is sent inside a `tool_result` block:

| API | Response |
|-----|----------|
| **Anthropic** | ✅ Consistently "orange tabby cat with golden-yellow eyes" |
| **OpenRouter** | ⚠️ Inconsistent - sometimes correct, often hallucinates wrong colors/scenes |

**The bug is intermittent.** Running the same request multiple times against OpenRouter yields different results:
- Sometimes correct: "orange/ginger tabby"
- Often wrong: "gray tabby", "brown and black coloring", "winter landscape", etc.

Anthropic's API returns consistent, correct results every time.

## Reproduction

### 1. Setup

```bash
git clone https://github.com/YOUR_USERNAME/openrouter-image-bug
cd openrouter-image-bug
chmod +x generate-repro.sh test.sh
./generate-repro.sh
```

### 2. Set API keys

```bash
export ANTHROPIC_API_KEY="your-key"
export OPENROUTER_API_KEY="your-key"
```

### 3. Run test

```bash
./test.sh
```

## Request Structure

The issue occurs when an image is nested inside a `tool_result`:

```json
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
          "path": { "type": "string" }
        },
        "required": ["path"]
      }
    }
  ],
  "messages": [
    {
      "role": "user",
      "content": "Read the image at cat.jpg and describe what you see"
    },
    {
      "role": "assistant",
      "content": [
        {
          "type": "tool_use",
          "id": "toolu_01ABC123",
          "name": "read_image",
          "input": { "path": "cat.jpg" }
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
                "data": "<BASE64_IMAGE_DATA>"
              }
            }
          ]
        }
      ]
    }
  ]
}
```

## Key Finding

- ✅ **Images in direct user messages** work correctly on both APIs
- ❌ **Images inside `tool_result` blocks** fail only on OpenRouter

This suggests OpenRouter is not correctly passing image data to the upstream model when it's nested inside a tool_result content block.

## Sample Outputs

### Anthropic (Consistently Correct)
> "This image shows a beautiful orange tabby cat (also known as a ginger or marmalade cat). The cat has striking golden-yellow eyes that are looking slightly to the side, giving it an alert and curious expression..."

### OpenRouter (Inconsistent - varies each run)

Sometimes correct:
> "I see a photograph of a cat. The cat appears to be an orange/ginger tabby with distinctive striped markings..."

Often incorrect:
> "Classic tabby stripes with a mix of brown, gray, and black coloring"

> "The cat has beautiful tabby markings with grey/brown striped fur"

> "This image shows a scenic winter landscape photograph. The scene captures a snow-covered mountain..."

## Environment

- Model: `claude-opus-4-5-20251101`
- OpenRouter endpoint: `https://openrouter.ai/api/v1/messages`
- Date discovered: 2026-01-28
