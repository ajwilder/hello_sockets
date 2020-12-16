
import {Socket} from "phoenix"

// let socket = new Socket("/socket", {})
//
// socket.connect()
//
// export default socket
//
// const channel = socket.channel("ping")
//
// channel.join()
//   .receive("ok", (resp) => { console.log("Joined ping", resp);})
//   .receive("error", (resp) => {console.log("Unable to join ping", resp)})
//
//
// console.log("send ping")
// channel.push("ping", {})
//   .receive("ok", (resp) => console.log("receive", resp.ping))
//
//
// console.log("send pong");
// channel.push("pong", {})
//   .receive("ok", (resp) => console.log("won't happen"))
//   .receive("error", (resp) => console.log("error"))
//   .receive("timeout", (resp) => console.log("pong message timeout"))
//
// channel.push("param_ping", { error: true} )
//   .receive("error", (resp) => console.log("param_ping error", resp))
// channel.push("param_ping", { error: false} )
//   .receive("ok", (resp) => console.log("param_ping ok", resp))
//
//
// channel.on("send_ping", (payload) => {
//   console.log("ping requested", payload);
//   channel.push("ping", {})
//     .receive("ok", (resp) => console.log("ping:", resp.ping))
// })
//
// channel.push("invalid", {})
//   .receive("ok", (resp) => console.log("won't happen!"))
//   .receive("error", (resp) => console.log("this neither"))
//   .receive("timeout", (resp) => console.log("invalid event timeout"))
//
//
const authSocket = new Socket("/auth_socket",{
  params: { token: window.authToken}
})
authSocket.onOpen(() => console.log('authSocket connected'))
authSocket.connect()


// const recurringChannel = authSocket.channel("recurring")
//
// recurringChannel.on("new_token", (payload) => {
//   console.log("received new auth token", payload);
// })
// recurringChannel.join()
//
// const dupeChannel = socket.channel("dupe")
//
// dupeChannel.on("number", (payload) => {
//   console.log("new number received", payload);
// })
// dupeChannel.join()
//
// const statsSocket = new Socket("/stats_socket", {})
// statsSocket.connect()
//
// const statsChannelInvalid = statsSocket.channel("invalid")
// statsChannelInvalid.join()
//   .receive("error", () => statsChannelInvalid.leave())
//
// const statsChannelValid = statsSocket.channel("valid")
// statsChannelValid.join()
//
// for (let i = 0; i < 5; i++) {
//   statsChannelValid.push("ping", {})
// }
//
//
// const slowStatsSocket = new Socket("/stats_socket", {})
// slowStatsSocket.connect()
//
// const slowStatsChannel = slowStatsSocket.channel('valid')
// slowStatsChannel.join()
//
// for (let i = 0; i < 5; i++) {
//   slowStatsChannel.push("slow_ping", {})
//     .receive("ok", () => console.log("Slow ping response received", i))
// }
// console.log("5 slow pings requested");
//
//
// const fastStatsSocket = new Socket("/stats_socket", {})
// fastStatsSocket.connect()
//
// const fastStatsChannel = fastStatsSocket.channel('valid')
// fastStatsChannel.join()
//
// for (let i = 0; i < 5; i++) {
//   fastStatsChannel.push("parallel_slow_ping", {})
//     .receive("ok", () => console.log("Parallel ping response received", i))
// }
// console.log("5 parallel slow pings requested");


const authUserChannel = authSocket.channel(`user:${window.userID}`)
authUserChannel.on("push", (payload) => {
  console.log("received auth user push", payload);
})
authUserChannel.on("push_timed", (payload) => {
  console.log("received auth user push", payload);
})
authUserChannel.join()
