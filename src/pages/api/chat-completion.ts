import { Message } from '@/models';
import { createParser, ParsedEvent, ReconnectInterval } from 'eventsource-parser';

export const config = {
  runtime: 'edge'
};

const handler = async (req: Request): Promise<Response> => {
  try {
    const { messages } = (await req.json()) as { messages: Message[] };
    const charLimit = 12000;
    let charCount = 0;
    let messagesToSend = [];

    for (let i = 0; i < messages.length; i++) {
      const message = messages[i];
      if (charCount + message.content.length > charLimit) {
        break;
      }
      charCount += message.content.length;
      messagesToSend.push(message);
    }

    const apiUrl = process.env.OPENAI_API_BASE_URL || 'http://router.paxel.ca:6501/api/generate';

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'llama3',
        stream: false,
        prompt: messagesToSend.map(m => m.content).join('\n'),
      }),
    });

    if (!response.ok) {
      throw new Error(`Error: ${response.statusText}`);
    }

    const data = await response.json();
    return new Response(JSON.stringify(data.response), { status: 200 });
  } catch (error) {
    console.error(error);
    return new Response('Error', { status: 500 });
  }
};

export default handler;
