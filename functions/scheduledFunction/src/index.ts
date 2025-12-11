import { HttpFunction } from '@google-cloud/functions-framework';

export const myTypescriptFunction: HttpFunction = (req, res) => {
  res.status(200).send('Hello World from TypeScript!');
};