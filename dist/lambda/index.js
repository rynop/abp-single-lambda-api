var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
const processEvent = (event, context) => __awaiter(this, void 0, void 0, function* () {
    var response = {
        statusCode: 200,
        headers: {},
        body: JSON.stringify({ message: 'Hello World!' }),
        isBase64Encoded: false
    };
    console.log(response);
    return response;
});
exports.handler = (event, context) => __awaiter(this, void 0, void 0, function* () {
    return processEvent(event, context);
});
//# sourceMappingURL=index.js.map