import 'whatwg-fetch';
import { TextEncoder, TextDecoder } from 'util';

// Add global Response if not available
if (!global.Response) {
  global.Response = Response;
}

// Add global Request if not available
if (!global.Request) {
  global.Request = Request;
}

// Add TextEncoder/TextDecoder
global.TextEncoder = TextEncoder;
global.TextDecoder = TextDecoder;