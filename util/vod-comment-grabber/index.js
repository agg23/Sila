import * as fs from "fs";
import * as util from "util";
import {
  authorization,
  clientId,
  clientIntegrity,
  clientSessionId,
  clientVersion,
  xDeviceId,
} from "./keys";

const videoId = "2143415927";

const parseComment = (comment) => {
  const cursor = comment["cursor"];
  const commentContent = comment["node"];

  const displayName = commentContent["commenter"]["displayName"];
  const color = commentContent["userColor"];
  const contentOffsetSeconds = commentContent["contentOffsetSeconds"];

  const messages = commentContent["message"]["fragments"];

  return {
    displayName,
    color,
    contentOffsetSeconds,
    messages,
    cursor,
  };
};

const parsePage = (page) => {
  const comments = page[0]["data"]["video"]["comments"]["edges"];

  return comments.map(parseComment);
};

const requestPage = async (cursor) => {
  const response = await fetch("https://gql.twitch.tv/gql", {
    method: "POST",
    body: JSON.stringify([
      {
        operationName: "VideoCommentsByOffsetOrCursor",
        variables: {
          videoID: videoId,
          cursor,
        },
        extensions: {
          persistedQuery: {
            version: 1,
            sha256Hash:
              "b70a3591ff0f4e0313d126c6a1502d79a1c02baebb288227c582044aa76adf6a",
          },
        },
      },
    ]),
    headers: {
      Authorization: authorization,
      "Client-Id": clientId,
      "Client-Integrity": clientIntegrity,
      "Client-Session-Id": clientSessionId,
      "Client-Version": clientVersion,
      "User-Agent":
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:125.0) Gecko/20100101 Firefox/125.0",
      "X-Device-Id": xDeviceId,
    },
  });

  const json = await response.json();

  // console.log(json);
  console.dir(json, { depth: null });

  return parsePage(json);
};

const sleep = async (durationMs) =>
  new Promise((resolve, _reject) => setTimeout(resolve, durationMs));

const requestNPages = async (pageCount) => {
  const foundComments = [];
  let cursor = startCursor;

  for (let i = 0; i < pageCount; i++) {
    try {
      const pageComments = await requestPage(cursor);

      const lastItem = pageComments[pageComments.length - 1];
      cursor = lastItem.cursor;

      foundComments.push(...pageComments);

      await sleep(3000);
    } catch (error) {
      console.error(error);
    }
  }

  return foundComments;
};

const requesetAndDump = async (pageCount) => {
  const comments = await requestNPages(pageCount);

  fs.writeFile("comments.json", JSON.stringify(comments), () => {});
};

requesetAndDump(10);
